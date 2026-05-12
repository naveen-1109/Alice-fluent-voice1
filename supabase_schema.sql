-- ==========================================
-- SUPABASE SCHEMA FOR FLUENTVOICE APP
-- ==========================================

-- 1. Create public.users table (links to auth.users)
CREATE TABLE public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('patient', 'therapist', 'admin')),
    phone TEXT,
    profile_image TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Create therapists table
CREATE TABLE public.therapists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE UNIQUE,
    specialization TEXT,
    experience INTEGER,
    availability JSONB,
    rating NUMERIC(3,2) DEFAULT 0.0,
    bio TEXT
);

-- 3. Create patients table
CREATE TABLE public.patients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE UNIQUE,
    age INTEGER,
    medical_notes TEXT,
    assigned_therapist UUID REFERENCES public.therapists(id) ON DELETE SET NULL
);

-- 4. Create appointments table
CREATE TABLE public.appointments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    therapist_id UUID NOT NULL REFERENCES public.therapists(id) ON DELETE CASCADE,
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    status TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'completed', 'cancelled')),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 5. Create therapy_sessions table
CREATE TABLE public.therapy_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    therapist_id UUID REFERENCES public.therapists(id) ON DELETE SET NULL,
    session_notes TEXT,
    progress_score INTEGER CHECK (progress_score BETWEEN 0 AND 100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 6. Create voice_records table
CREATE TABLE public.voice_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    audio_url TEXT NOT NULL,
    analysis_result JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 7. Create notifications table
CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ==========================================
-- ROW LEVEL SECURITY (RLS)
-- ==========================================

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.therapists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.therapy_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.voice_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Users can read their own profile
CREATE POLICY "Users can view own profile" ON public.users FOR SELECT USING (auth.uid() = id);
-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id);

-- Therapists can be read by anyone, but updated only by themselves
CREATE POLICY "Therapists are viewable by all" ON public.therapists FOR SELECT USING (true);
CREATE POLICY "Therapists can update own data" ON public.therapists FOR UPDATE USING (auth.uid() = user_id);

-- Patients can view their own data, and their assigned therapist can view it
CREATE POLICY "Patients view own data" ON public.patients FOR SELECT USING (auth.uid() = user_id);

-- Appointments can be viewed/edited by the involved patient or therapist
CREATE POLICY "View own appointments (Patient)" ON public.appointments FOR SELECT USING (
    patient_id IN (SELECT id FROM public.patients WHERE user_id = auth.uid())
);
CREATE POLICY "View own appointments (Therapist)" ON public.appointments FOR SELECT USING (
    therapist_id IN (SELECT id FROM public.therapists WHERE user_id = auth.uid())
);

-- Voice records can be uploaded/viewed by patient
CREATE POLICY "Patients can upload and view own voice records" ON public.voice_records FOR ALL USING (
    patient_id IN (SELECT id FROM public.patients WHERE user_id = auth.uid())
);

-- Notifications are private to the user
CREATE POLICY "Users can manage own notifications" ON public.notifications FOR ALL USING (auth.uid() = user_id);

-- ==========================================
-- STORAGE BUCKETS
-- ==========================================
-- Create bucket for profile images
INSERT INTO storage.buckets (id, name, public) VALUES ('profiles', 'profiles', true);
-- Create bucket for audio recordings
INSERT INTO storage.buckets (id, name, public) VALUES ('recordings', 'recordings', false);

-- Set storage policies (Requires storage.objects table RLS)
CREATE POLICY "Profile images are public" ON storage.objects FOR SELECT USING (bucket_id = 'profiles');
CREATE POLICY "Authenticated users can upload profiles" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'profiles' AND auth.role() = 'authenticated');

CREATE POLICY "Users can view own recordings" ON storage.objects FOR SELECT USING (bucket_id = 'recordings' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Users can upload own recordings" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'recordings' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Create Auth Trigger to automatically create a user record upon signup
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, full_name, email, role)
    VALUES (new.id, new.raw_user_meta_data->>'full_name', new.email, COALESCE(new.raw_user_meta_data->>'role', 'patient'));
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
