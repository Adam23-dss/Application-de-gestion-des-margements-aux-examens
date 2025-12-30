-- ============================================
-- PARTIE 2 : VUES, DONNÉES ET TRIGGERS
-- ============================================

-- ============================================
-- VUES UTILES
-- ============================================

-- Vue pour les statistiques des examens
CREATE OR REPLACE VIEW exam_statistics AS
SELECT 
    e.id,
    e.name as exam_name,
    c.name as course_name,
    e.exam_date,
    e.start_time,
    e.end_time,
    r.name as room_name,
    COUNT(DISTINCT er.student_id) as total_registered,
    COUNT(DISTINCT CASE WHEN a.status = 'present' THEN a.student_id END) as present_count,
    COUNT(DISTINCT CASE WHEN a.status = 'absent' THEN a.student_id END) as absent_count,
    COUNT(DISTINCT CASE WHEN a.status = 'late' THEN a.student_id END) as late_count,
    ROUND(
        COUNT(DISTINCT CASE WHEN a.status = 'present' THEN a.student_id END) * 100.0 / 
        NULLIF(COUNT(DISTINCT er.student_id), 0), 2
    ) as attendance_rate
FROM exams e
LEFT JOIN courses c ON e.course_id = c.id
LEFT JOIN rooms r ON e.room_id = r.id
LEFT JOIN exam_registrations er ON e.id = er.exam_id
LEFT JOIN attendance a ON e.id = a.exam_id AND er.student_id = a.student_id
GROUP BY e.id, e.name, c.name, e.exam_date, e.start_time, e.end_time, r.name;

-- Vue pour le dashboard admin
CREATE OR REPLACE VIEW admin_dashboard_stats AS
SELECT 
    (SELECT COUNT(*) FROM students) as total_students,
    (SELECT COUNT(*) FROM users) as total_users,
    (SELECT COUNT(*) FROM exams) as total_exams,
    (SELECT COUNT(*) FROM exams WHERE status = 'in_progress') as active_exams,
    (SELECT COUNT(*) FROM attendance) as total_attendance_records,
    ROUND(
        (SELECT COUNT(*) FROM attendance WHERE status = 'present') * 100.0 / 
        NULLIF((SELECT COUNT(*) FROM attendance), 0), 2
    ) as global_attendance_rate;

-- ============================================
-- DONNÉES DE TEST
-- ============================================

-- Utilisateurs (mot de passe: password123)
INSERT INTO users (email, password, first_name, last_name, role, ufr, department) VALUES
('admin@univ.fr', '$2b$10$N9qo8uLOickgx2ZMRZoMye5G6WZWJKNBqL8JYJ2NfZ.7QKQYQZ/yK', 'Admin', 'System', 'admin', 'Sciences', 'Informatique'),
('surveillant@univ.fr', '$2b$10$N9qo8uLOickgx2ZMRZoMye5G6WZWJKNBqL8JYJ2NfZ.7QKQYQZ/yK', 'Jean', 'Dupont', 'supervisor', 'Sciences', 'Mathématiques')
ON CONFLICT (email) DO NOTHING;

-- Étudiants
INSERT INTO students (student_code, first_name, last_name, email, ufr, department, promotion) VALUES
('ETU20240001', 'Paul', 'Durand', 'paul.durand@etu.univ.fr', 'Sciences', 'Informatique', '2024'),
('ETU20240002', 'Sophie', 'Leroy', 'sophie.leroy@etu.univ.fr', 'Sciences', 'Mathématiques', '2024'),
('ETU20240003', 'Luc', 'Moreau', 'luc.moreau@etu.univ.fr', 'Lettres', 'Philosophie', '2024')
ON CONFLICT (student_code) DO NOTHING;

-- Cours
INSERT INTO courses (code, name, ufr, department, credits) VALUES
('INF101', 'Algorithmique', 'Sciences', 'Informatique', 6),
('MAT201', 'Mathématiques', 'Sciences', 'Mathématiques', 5),
('PHI301', 'Philosophie', 'Lettres', 'Philosophie', 4)
ON CONFLICT (code) DO NOTHING;

-- Salles
INSERT INTO rooms (code, name, building, floor, capacity) VALUES
('A201', 'Amphi 201', 'Bâtiment A', 2, 150),
('B103', 'Salle B103', 'Bâtiment B', 1, 40)
ON CONFLICT (code) DO NOTHING;

-- Examens
INSERT INTO exams (course_id, name, exam_date, start_time, end_time, room_id, supervisor_id, status) VALUES
(1, 'Examen Algorithmique', '2024-01-20', '09:00', '12:00', 1, 2, 'scheduled'),
(2, 'Examen Mathématiques', '2024-01-22', '14:00', '17:00', 2, 2, 'scheduled')
ON CONFLICT DO NOTHING;

-- Inscriptions
INSERT INTO exam_registrations (exam_id, student_id) VALUES
(1, 1), (1, 2), (1, 3),
(2, 1), (2, 2)
ON CONFLICT DO NOTHING;

-- Présences
INSERT INTO attendance (exam_id, student_id, supervisor_id, status, validation_time) VALUES
(1, 1, 2, 'present', '2024-01-20 09:05:00'),
(1, 2, 2, 'present', '2024-01-20 09:07:00'),
(1, 3, 2, 'absent', NULL)
ON CONFLICT DO NOTHING;

-- ============================================
-- TRIGGERS
-- ============================================

-- Fonction pour updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers pour updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_students_updated_at BEFORE UPDATE ON students
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_exams_updated_at BEFORE UPDATE ON exams
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_attendance_updated_at BEFORE UPDATE ON attendance
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Fonction pour historiser les changements
CREATE OR REPLACE FUNCTION log_attendance_change()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO attendance_history (attendance_id, old_status, new_status, changed_by)
        VALUES (NEW.id, OLD.status, NEW.status, NEW.supervisor_id);
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER log_attendance_changes AFTER UPDATE ON attendance
    FOR EACH ROW EXECUTE FUNCTION log_attendance_change();

-- ============================================
-- VÉRIFICATION FINALE
-- ============================================
DO $$
DECLARE
    user_count INTEGER;
    student_count INTEGER;
    exam_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO user_count FROM users;
    SELECT COUNT(*) INTO student_count FROM students;
    SELECT COUNT(*) INTO exam_count FROM exams;
    
    RAISE NOTICE '✅ PARTIE 2 : Données et triggers créés !';
    RAISE NOTICE '📊 Résumé:';
    RAISE NOTICE '   - % utilisateurs', user_count;
    RAISE NOTICE '   - % étudiants', student_count;
    RAISE NOTICE '   - % examens', exam_count;
    RAISE NOTICE '   - Vues et triggers actifs';
END $$;