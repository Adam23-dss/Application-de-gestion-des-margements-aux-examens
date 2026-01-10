const Joi = require('joi');

// ==================== STUDENT VALIDATION ====================

// Schéma de validation pour la création d'étudiant
const studentSchema = Joi.object({
  student_code: Joi.string()
    .pattern(/^[A-Z0-9]{4,20}$/)
    .required()
    .messages({
      'string.pattern.base': 'Le code étudiant doit contenir 4 à 20 caractères (lettres majuscules et chiffres uniquement)',
      'any.required': 'Le code étudiant est requis'
    }),
    
  first_name: Joi.string()
    .min(2)
    .max(50)
    .pattern(/^[A-Za-zÀ-ÿ\s\-']+$/)
    .required()
    .messages({
      'string.min': 'Le prénom doit contenir au moins 2 caractères',
      'string.max': 'Le prénom ne peut pas dépasser 50 caractères',
      'string.pattern.base': 'Le prénom ne peut contenir que des lettres, espaces, tirets et apostrophes',
      'any.required': 'Le prénom est requis'
    }),
    
  last_name: Joi.string()
    .min(2)
    .max(50)
    .pattern(/^[A-Za-zÀ-ÿ\s\-']+$/)
    .required()
    .messages({
      'string.min': 'Le nom doit contenir au moins 2 caractères',
      'string.max': 'Le nom ne peut pas dépasser 50 caractères',
      'string.pattern.base': 'Le nom ne peut contenir que des lettres, espaces, tirets et apostrophes',
      'any.required': 'Le nom est requis'
    }),
    
  email: Joi.string()
    .email()
    .optional()
    .allow(null, '')
    .messages({
      'string.email': 'Email invalide'
    }),
    
  ufr: Joi.string()
    .min(2)
    .max(100)
    .required()
    .messages({
      'string.min': 'L\'UFR doit contenir au moins 2 caractères',
      'string.max': 'L\'UFR ne peut pas dépasser 100 caractères',
      'any.required': 'L\'UFR est requise'
    }),
    
  department: Joi.string()
    .min(2)
    .max(100)
    .required()
    .messages({
      'string.min': 'Le département doit contenir au moins 2 caractères',
      'string.max': 'Le département ne peut pas dépasser 100 caractères',
      'any.required': 'Le département est requis'
    }),
    
  promotion: Joi.string()
    .max(50)
    .optional()
    .allow(null, '')
});

// Schéma pour la mise à jour (tous les champs optionnels)
const studentUpdateSchema = Joi.object({
  first_name: Joi.string()
    .min(2)
    .max(50)
    .pattern(/^[A-Za-zÀ-ÿ\s\-']+$/)
    .optional(),
    
  last_name: Joi.string()
    .min(2)
    .max(50)
    .pattern(/^[A-Za-zÀ-ÿ\s\-']+$/)
    .optional(),
    
  email: Joi.string()
    .email()
    .optional()
    .allow(null, '')
    .messages({
      'string.email': 'Email invalide'
    }),
    
  ufr: Joi.string()
    .min(2)
    .max(100)
    .optional(),
    
  department: Joi.string()
    .min(2)
    .max(100)
    .optional(),
    
  promotion: Joi.string()
    .max(50)
    .optional()
    .allow(null, '')
});

// Middleware de validation pour la création d'étudiant
exports.validateStudent = (req, res, next) => {
  const { error, value } = studentSchema.validate(req.body, {
    abortEarly: false,
    stripUnknown: true
  });
  
  if (error) {
    const errors = error.details.map(detail => ({
      field: detail.path[0],
      message: detail.message
    }));
    
    return res.status(400).json({
      success: false,
      error: 'VALIDATION_ERROR',
      message: 'Erreur de validation des données étudiant',
      errors: errors
    });
  }
  
  // Normaliser le code étudiant en majuscules
  if (value.student_code) {
    value.student_code = value.student_code.toUpperCase();
  }
  
  req.validatedData = value;
  next();
};

// Middleware de validation pour la mise à jour d'étudiant
exports.validateStudentUpdate = (req, res, next) => {
  const { error, value } = studentUpdateSchema.validate(req.body, {
    abortEarly: false,
    stripUnknown: true
  });
  
  if (error) {
    const errors = error.details.map(detail => ({
      field: detail.path[0],
      message: detail.message
    }));
    
    return res.status(400).json({
      success: false,
      error: 'VALIDATION_ERROR',
      message: 'Erreur de validation des données étudiant',
      errors: errors
    });
  }
  
  // Vérifier qu'au moins un champ est fourni
  if (Object.keys(value).length === 0) {
    return res.status(400).json({
      success: false,
      error: 'NO_DATA_PROVIDED',
      message: 'Aucune donnée fournie pour la mise à jour'
    });
  }
  
  req.validatedData = value;
  next();
};

// Schéma pour la création d'examen
const examSchema = Joi.object({
  course_id: Joi.number()
    .integer()
    .optional(),
    
  name: Joi.string()
    .min(3)
    .max(200)
    .required()
    .messages({
      'string.min': 'Le nom doit contenir au moins 3 caractères',
      'any.required': 'Le nom est requis'
    }),
    
  description: Joi.string()
    .max(500)
    .optional(),
    
  exam_date: Joi.date()
    .iso()
    .required()
    .messages({
      'date.format': 'La date doit être au format YYYY-MM-DD',
      'any.required': 'La date est requise'
    }),
    
  start_time: Joi.string()
    .pattern(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/)
    .required()
    .messages({
      'string.pattern.base': 'L\'heure de début doit être au format HH:MM',
      'any.required': 'L\'heure de début est requise'
    }),
    
  end_time: Joi.string()
    .pattern(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/)
    .required()
    .messages({
      'string.pattern.base': 'L\'heure de fin doit être au format HH:MM',
      'any.required': 'L\'heure de fin est requise'
    }),
    
  room_id: Joi.number()
    .integer()
    .optional(),
    
  supervisor_id: Joi.number()
    .integer()
    .optional()
});

// Schéma pour la mise à jour d'examen
const examUpdateSchema = Joi.object({
  course_id: Joi.number()
    .integer()
    .optional(),
    
  name: Joi.string()
    .min(3)
    .max(200)
    .optional(),
    
  description: Joi.string()
    .max(500)
    .optional(),
    
  exam_date: Joi.date()
    .iso()
    .optional(),
    
  start_time: Joi.string()
    .pattern(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/)
    .optional(),
    
  end_time: Joi.string()
    .pattern(/^([01]?[0-9]|2[0-3]):[0-5][0-9]$/)
    .optional(),
    
  room_id: Joi.number()
    .integer()
    .optional(),
    
  supervisor_id: Joi.number()
    .integer()
    .optional(),
    
  status: Joi.string()
    .valid('scheduled', 'in_progress', 'completed', 'cancelled')
    .optional()
});

// Ajouter les middlewares
exports.validateExam = (req, res, next) => {
  const { error, value } = examSchema.validate(req.body, {
    abortEarly: false,
    stripUnknown: true
  });
  
  if (error) {
    const errors = error.details.map(detail => ({
      field: detail.path[0],
      message: detail.message
    }));
    
    return res.status(400).json({
      success: false,
      error: 'VALIDATION_ERROR',
      message: 'Erreur de validation',
      errors: errors
    });
  }
  
  // Vérifier que end_time > start_time
  if (value.start_time && value.end_time) {
    const start = new Date(`2000-01-01T${value.start_time}`);
    const end = new Date(`2000-01-01T${value.end_time}`);
    
    if (end <= start) {
      return res.status(400).json({
        success: false,
        error: 'INVALID_TIME_RANGE',
        message: 'L\'heure de fin doit être après l\'heure de début'
      });
    }
  }
  
  req.validatedData = value;
  next();
};

exports.validateExamUpdate = (req, res, next) => {
  const { error, value } = examUpdateSchema.validate(req.body, {
    abortEarly: false,
    stripUnknown: true
  });
  
  if (error) {
    const errors = error.details.map(detail => ({
      field: detail.path[0],
      message: detail.message
    }));
    
    return res.status(400).json({
      success: false,
      error: 'VALIDATION_ERROR',
      message: 'Erreur de validation',
      errors: errors
    });
  }
  
  // Vérifier qu'au moins un champ est fourni
  if (Object.keys(value).length === 0) {
    return res.status(400).json({
      success: false,
      error: 'NO_DATA_PROVIDED',
      message: 'Aucune donnée fournie pour la mise à jour'
    });
  }
  
  req.validatedData = value;
  next();
};

// Schéma pour validation de présence
const attendanceSchema = Joi.object({
  exam_id: Joi.number()
    .integer()
    .required()
    .messages({
      'any.required': 'ID examen requis'
    }),
    
  student_code: Joi.string()
    .pattern(/^[A-Z0-9]{4,20}$/)
    .required()
    .messages({
      'string.pattern.base': 'Code étudiant invalide',
      'any.required': 'Code étudiant requis'
    }),
    
  status: Joi.string()
    .valid('present', 'absent', 'late', 'excused')
    .default('present'),
    
  validation_method: Joi.string()
    .valid('manual', 'qr_code', 'nfc')
    .default('manual')
});

// Middleware de validation pour présence
exports.validateAttendance = (req, res, next) => {
  const { error, value } = attendanceSchema.validate(req.body, {
    abortEarly: false,
    stripUnknown: true
  });
  
  if (error) {
    const errors = error.details.map(detail => ({
      field: detail.path[0],
      message: detail.message
    }));
    
    return res.status(400).json({
      success: false,
      error: 'VALIDATION_ERROR',
      message: 'Erreur de validation des données de présence',
      errors: errors
    });
  }
  
  req.validatedData = value;
  next();
};