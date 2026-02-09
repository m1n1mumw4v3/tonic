-- Tonic v1 Initial Schema
-- Run against Supabase Postgres

-- Users
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  first_name TEXT NOT NULL,
  email TEXT UNIQUE,
  auth_id UUID REFERENCES auth.users(id)
);

-- Onboarding Profile
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  age INTEGER NOT NULL,
  sex TEXT NOT NULL CHECK (sex IN ('male', 'female', 'other', 'prefer_not_to_say')),
  height_inches INTEGER,
  weight_lbs INTEGER,
  health_goals TEXT[] NOT NULL DEFAULT '{}',
  current_supplements JSONB DEFAULT '[]',
  allergies TEXT[] DEFAULT '{}',
  medications TEXT[] DEFAULT '{}',
  diet_type TEXT CHECK (diet_type IN ('omnivore', 'vegetarian', 'vegan', 'keto', 'paleo', 'pescatarian', 'other')),
  exercise_frequency TEXT CHECK (exercise_frequency IN ('none', '1-2_weekly', '3-4_weekly', '5+_weekly')),
  exercise_type TEXT[] DEFAULT '{}',
  sleep_hours_avg NUMERIC(3,1),
  caffeine_daily TEXT CHECK (caffeine_daily IN ('none', '1_cup', '2-3_cups', '4+_cups')),
  alcohol_weekly TEXT CHECK (alcohol_weekly IN ('none', '1-3_drinks', '4-7_drinks', '8+_drinks')),
  stress_level TEXT CHECK (stress_level IN ('low', 'moderate', 'high', 'very_high')),
  baseline_energy INTEGER CHECK (baseline_energy BETWEEN 0 AND 100),
  baseline_clarity INTEGER CHECK (baseline_clarity BETWEEN 0 AND 100),
  baseline_sleep INTEGER CHECK (baseline_sleep BETWEEN 0 AND 100),
  baseline_mood INTEGER CHECK (baseline_mood BETWEEN 0 AND 100),
  baseline_gut INTEGER CHECK (baseline_gut BETWEEN 0 AND 100),
  healthkit_enabled BOOLEAN DEFAULT FALSE
);

-- Supplement Knowledge Base
CREATE TABLE supplement_knowledge_base (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  common_dosage_range TEXT,
  recommended_timing TEXT,
  benefits TEXT[] DEFAULT '{}',
  contraindications TEXT[] DEFAULT '{}',
  drug_interactions TEXT[] DEFAULT '{}',
  notes TEXT,
  research_summary TEXT,
  is_active BOOLEAN DEFAULT TRUE
);

-- Supplement Plan
CREATE TABLE supplement_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  is_active BOOLEAN DEFAULT TRUE,
  version INTEGER DEFAULT 1,
  ai_reasoning TEXT
);

-- Plan Supplements
CREATE TABLE plan_supplements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id UUID REFERENCES supplement_plans(id) ON DELETE CASCADE,
  supplement_id UUID REFERENCES supplement_knowledge_base(id),
  custom_name TEXT,
  dosage TEXT NOT NULL,
  dosage_mg NUMERIC,
  timing TEXT NOT NULL CHECK (timing IN ('morning', 'afternoon', 'evening', 'bedtime', 'with_food', 'empty_stomach')),
  frequency TEXT DEFAULT 'daily' CHECK (frequency IN ('daily', 'every_other_day', 'weekly', 'as_needed')),
  reasoning TEXT,
  sort_order INTEGER DEFAULT 0
);

-- Daily Check-ins
CREATE TABLE daily_checkins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  checkin_date DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  sleep_score INTEGER CHECK (sleep_score BETWEEN 0 AND 100),
  energy_score INTEGER CHECK (energy_score BETWEEN 0 AND 100),
  clarity_score INTEGER CHECK (clarity_score BETWEEN 0 AND 100),
  mood_score INTEGER CHECK (mood_score BETWEEN 0 AND 100),
  gut_score INTEGER CHECK (gut_score BETWEEN 0 AND 100),
  wellbeing_score INTEGER CHECK (wellbeing_score BETWEEN 0 AND 100),
  notes TEXT,
  UNIQUE(user_id, checkin_date)
);

-- Supplement Intake Log
CREATE TABLE supplement_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  plan_supplement_id UUID REFERENCES plan_supplements(id),
  logged_date DATE NOT NULL,
  taken BOOLEAN DEFAULT FALSE,
  logged_at TIMESTAMPTZ DEFAULT NOW()
);

-- AI Insights
CREATE TABLE insights (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  insight_type TEXT CHECK (insight_type IN ('correlation', 'trend', 'recommendation', 'milestone')),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data_points_used INTEGER,
  dimension TEXT,
  is_read BOOLEAN DEFAULT FALSE,
  is_dismissed BOOLEAN DEFAULT FALSE
);

-- Streaks
CREATE TABLE user_streaks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  last_checkin_date DATE
);

-- Apple Health Data Cache
CREATE TABLE healthkit_data (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  sleep_hours NUMERIC(4,2),
  resting_heart_rate INTEGER,
  hrv_ms NUMERIC(5,1),
  steps INTEGER,
  active_minutes INTEGER,
  UNIQUE(user_id, date)
);

-- Row Level Security Policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE supplement_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE plan_supplements ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_checkins ENABLE ROW LEVEL SECURITY;
ALTER TABLE supplement_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE insights ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE healthkit_data ENABLE ROW LEVEL SECURITY;

-- Users can only see/modify their own data
CREATE POLICY "Users can view own data" ON users FOR SELECT USING (auth.uid() = auth_id);
CREATE POLICY "Users can update own data" ON users FOR UPDATE USING (auth.uid() = auth_id);

CREATE POLICY "Users can view own profile" ON user_profiles FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));
CREATE POLICY "Users can insert own profile" ON user_profiles FOR INSERT WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));
CREATE POLICY "Users can update own profile" ON user_profiles FOR UPDATE USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- Supplement knowledge base is public read
ALTER TABLE supplement_knowledge_base ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read supplements" ON supplement_knowledge_base FOR SELECT USING (true);

CREATE POLICY "Users can view own plans" ON supplement_plans FOR ALL USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));
CREATE POLICY "Users can view own plan supplements" ON plan_supplements FOR ALL USING (plan_id IN (SELECT id FROM supplement_plans WHERE user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())));
CREATE POLICY "Users can manage own checkins" ON daily_checkins FOR ALL USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));
CREATE POLICY "Users can manage own supplement logs" ON supplement_logs FOR ALL USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));
CREATE POLICY "Users can manage own insights" ON insights FOR ALL USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));
CREATE POLICY "Users can manage own streaks" ON user_streaks FOR ALL USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));
CREATE POLICY "Users can manage own healthkit data" ON healthkit_data FOR ALL USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));
