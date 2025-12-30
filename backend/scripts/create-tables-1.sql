-- ============================================
-- PARTIE 1 : CRÉATION DES TABLES ET STRUCTURE
-- ============================================

-- Supprimer les tables si elles existent
DROP TABLE IF EXISTS attendance_history;
DROP TABLE IF EXISTS attendance;
DROP TABLE IF EXISTS exam_registrations;
DROP TABLE IF EXISTS exams;
DROP TABLE IF EXISTS rooms;
DROP TABLE IF EXISTS courses;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS users;
DROP VIEW IF EXISTS exam_statistics;
DROP VIEW IF EXISTS admin_dashboard_stats;

-- ============================================
-- TABLE: users (Utilisateurs)
-- ============================================
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'supervisor' CHECK (role IN ('admin', 'supervisor')),
    ufr VARCHAR(100),
    department VARCHAR(100),
    phone VARCHAR(20),
    is_active BOOLEAN DEFAULT true,
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TABLE: students (Étudiants)
-- ============================================
CREATE TABLE students (
    id SERIAL PRIMARY KEY,
    student_code VARCHAR(50) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255),
    ufr VARCHAR(100) NOT NULL,
    department VARCHAR(100) NOT NULL,
    promotion VARCHAR(50),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TABLE: courses (Matières)
-- ============================================
CREATE TABLE courses (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    ufr VARCHAR(100),
    department VARCHAR(100),
    credits INTEGER,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TABLE: rooms (Salles)
-- ============================================
CREATE TABLE rooms (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    building VARCHAR(100),
    floor INTEGER,
    capacity INTEGER NOT NULL CHECK (capacity > 0),
    has_computer BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TABLE: exams (Examens)
-- ============================================
CREATE TABLE exams (
    id SERIAL PRIMARY KEY,
    course_id INTEGER REFERENCES courses(id),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    exam_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    room_id INTEGER REFERENCES rooms(id),
    supervisor_id INTEGER REFERENCES users(id),
    status VARCHAR(50) DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled')),
    total_students INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TABLE: exam_registrations (Inscriptions)
-- ============================================
CREATE TABLE exam_registrations (
    id SERIAL PRIMARY KEY,
    exam_id INTEGER NOT NULL REFERENCES exams(id) ON DELETE CASCADE,
    student_id INTEGER NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(exam_id, student_id)
);

-- ============================================
-- TABLE: attendance (Présences)
-- ============================================
CREATE TABLE attendance (
    id SERIAL PRIMARY KEY,
    exam_id INTEGER NOT NULL REFERENCES exams(id),
    student_id INTEGER NOT NULL REFERENCES students(id),
    supervisor_id INTEGER REFERENCES users(id),
    status VARCHAR(50) NOT NULL DEFAULT 'absent' CHECK (status IN ('present', 'absent', 'late', 'excused')),
    validation_time TIMESTAMP,
    validation_method VARCHAR(50) CHECK (validation_method IN ('manual', 'qr_code', 'nfc')),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(exam_id, student_id)
);

-- ============================================
-- TABLE: attendance_history (Historique)
-- ============================================
CREATE TABLE attendance_history (
    id SERIAL PRIMARY KEY,
    attendance_id INTEGER REFERENCES attendance(id) ON DELETE CASCADE,
    old_status VARCHAR(50),
    new_status VARCHAR(50),
    changed_by INTEGER REFERENCES users(id),
    change_reason TEXT,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- INDEXES pour performances
-- ============================================
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

CREATE INDEX idx_students_code ON students(student_code);
CREATE INDEX idx_students_ufr ON students(ufr);
CREATE INDEX idx_students_department ON students(department);

CREATE INDEX idx_exams_date ON exams(exam_date);
CREATE INDEX idx_exams_status ON exams(status);
CREATE INDEX idx_exams_supervisor ON exams(supervisor_id);
CREATE INDEX idx_exams_course ON exams(course_id);

CREATE INDEX idx_attendance_exam_id ON attendance(exam_id);
CREATE INDEX idx_attendance_student_id ON attendance(student_id);
CREATE INDEX idx_attendance_status ON attendance(status);
CREATE INDEX idx_attendance_validation_time ON attendance(validation_time);

CREATE INDEX idx_exam_registrations_exam ON exam_registrations(exam_id);
CREATE INDEX idx_exam_registrations_student ON exam_registrations(student_id);

DO $$
BEGIN
    RAISE NOTICE '✅ PARTIE 1 : Tables créées avec succès !';
END $$;