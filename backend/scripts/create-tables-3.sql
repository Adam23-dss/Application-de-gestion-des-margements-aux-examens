-- Créer la table pour l'historique des QR codes
CREATE TABLE IF NOT EXISTS qr_codes (
  id SERIAL PRIMARY KEY,
  exam_id INTEGER NOT NULL REFERENCES exams(id) ON DELETE CASCADE,
  student_id VARCHAR(50) NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  generated_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
  generated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  
  -- Pour le suivi d'utilisation (optionnel)
  scanned_at TIMESTAMP WITH TIME ZONE,
  scanned_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
  validation_id INTEGER REFERENCES attendance(id) ON DELETE SET NULL,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  -- Index pour les recherches fréquentes
  INDEX idx_qr_codes_exam (exam_id),
  INDEX idx_qr_codes_student (student_id),
  INDEX idx_qr_codes_generated_by (generated_by),
  INDEX idx_qr_codes_expires_at (expires_at)
);

-- Ajouter un commentaire descriptif
COMMENT ON TABLE qr_codes IS 'Historique des QR codes générés pour le suivi et l audit';
COMMENT ON COLUMN qr_codes.exam_id IS 'Examen concerné';
COMMENT ON COLUMN qr_codes.student_id IS 'Étudiant concerné';
COMMENT ON COLUMN qr_codes.generated_by IS 'Utilisateur qui a généré le QR code';
COMMENT ON COLUMN qr_codes.generated_at IS 'Date/heure de génération';
COMMENT ON COLUMN qr_codes.expires_at IS 'Date/heure d expiration (30 minutes après génération)';
COMMENT ON COLUMN qr_codes.scanned_at IS 'Date/heure du scan (si utilisé)';
COMMENT ON COLUMN qr_codes.scanned_by IS 'Utilisateur qui a scanné le QR code';
COMMENT ON COLUMN qr_codes.validation_id IS 'Lien vers la validation de présence';