const PDFDocument = require('pdfkit');
const fs = require('fs');
const path = require('path');

class PDFService {
  // Générer un rapport d'examen
  static async generateExamReport(exam, attendanceList) {
    return new Promise((resolve, reject) => {
      try {
        const doc = new PDFDocument({ margin: 50 });
        const chunks = [];
        
        doc.on('data', chunk => chunks.push(chunk));
        doc.on('end', () => resolve(Buffer.concat(chunks)));
        doc.on('error', reject);
        
        // En-tête
        this.addHeader(doc, exam);
        
        // Informations examen
        this.addExamInfo(doc, exam);
        
        // Statistiques
        this.addStatistics(doc, attendanceList);
        
        // Liste des présences
        this.addAttendanceList(doc, attendanceList);
        
        // Pied de page
        this.addFooter(doc);
        
        doc.end();
      } catch (error) {
        reject(error);
      }
    });
  }

  static addHeader(doc, exam) {
    // Logo/titre université
    doc.fontSize(20)
       .font('Helvetica-Bold')
       .text('UNIVERSITÉ NUMÉRIQUE', { align: 'center' });
    
    doc.moveDown(0.5);
    doc.fontSize(16)
       .font('Helvetica')
       .text('FEUILLE DE PRÉSENCE', { align: 'center' });
    
    doc.moveDown(0.5);
    doc.fontSize(14)
       .text(exam.name, { align: 'center' });
    
    doc.moveDown(1);
    this.addHorizontalLine(doc);
  }

  static addExamInfo(doc, exam) {
    doc.fontSize(11)
       .font('Helvetica-Bold')
       .text('INFORMATIONS DE L\'EXAMEN', { underline: true });
    
    doc.moveDown(0.5);
    doc.font('Helvetica');
    
    const info = [
      `Date: ${new Date(exam.exam_date).toLocaleDateString('fr-FR')}`,
      `Heure: ${exam.start_time} - ${exam.end_time}`,
      `Salle: ${exam.room_name || 'Non définie'}`,
      `Surveillant: ${exam.supervisor_name || 'Non attribué'}`,
      `Statut: ${this.translateStatus(exam.status)}`
    ];
    
    info.forEach(line => {
      doc.text(`• ${line}`);
    });
    
    doc.moveDown(1);
    this.addHorizontalLine(doc);
  }

  static addStatistics(doc, attendanceList) {
    const stats = this.calculateStats(attendanceList);
    
    doc.fontSize(11)
       .font('Helvetica-Bold')
       .text('STATISTIQUES', { underline: true });
    
    doc.moveDown(0.5);
    doc.font('Helvetica');
    
    const statsText = [
      `Total étudiants: ${stats.total}`,
      `Présents: ${stats.present} (${stats.presentPercentage}%)`,
      `Absents: ${stats.absent} (${stats.absentPercentage}%)`,
      `En retard: ${stats.late} (${stats.latePercentage}%)`,
      `Excusés: ${stats.excused} (${stats.excusedPercentage}%)`
    ];
    
    statsText.forEach(line => {
      doc.text(`• ${line}`);
    });
    
    doc.moveDown(1);
    this.addHorizontalLine(doc);
  }

  static addAttendanceList(doc, attendanceList) {
    doc.fontSize(11)
       .font('Helvetica-Bold')
       .text('LISTE DES PRÉSENCES', { underline: true });
    
    doc.moveDown(0.5);
    
    // En-tête du tableau
    doc.font('Helvetica-Bold');
    this.addTableRow(doc, ['N°', 'Code', 'Nom', 'Prénom', 'Statut', 'Heure'], true);
    
    // Lignes de données
    doc.font('Helvetica');
    attendanceList.forEach((att, index) => {
      this.addTableRow(doc, [
        (index + 1).toString(),
        att.student_code,
        att.last_name,
        att.first_name,
        this.translateStatus(att.status),
        att.validation_time ? new Date(att.validation_time).toLocaleTimeString('fr-FR') : 'N/A'
      ], false);
    });
    
    doc.moveDown(1);
  }

  static addTableRow(doc, columns, isHeader = false) {
    const colWidths = [30, 70, 100, 100, 60, 80];
    let x = doc.x;
    
    columns.forEach((col, i) => {
      doc.text(col, x, doc.y, {
        width: colWidths[i],
        align: 'left'
      });
      x += colWidths[i];
    });
    
    doc.moveDown(0.5);
    
    if (isHeader) {
      this.addHorizontalLine(doc, 1);
      doc.moveDown(0.5);
    }
  }

  static addFooter(doc) {
    const pageHeight = doc.page.height;
    const footerY = pageHeight - 50;
    
    doc.y = footerY;
    this.addHorizontalLine(doc);
    
    doc.fontSize(9)
       .font('Helvetica-Oblique')
       .text('Généré le ' + new Date().toLocaleDateString('fr-FR'), 50, footerY + 15);
    
    doc.text(`Page ${doc.page.number}`, 0, footerY + 15, { align: 'right', width: doc.page.width - 100 });
  }

  static addHorizontalLine(doc, thickness = 0.5) {
    doc.moveTo(50, doc.y)
       .lineTo(doc.page.width - 50, doc.y)
       .lineWidth(thickness)
       .stroke();
  }

  static calculateStats(attendanceList) {
    const total = attendanceList.length;
    const present = attendanceList.filter(a => a.status === 'present').length;
    const absent = attendanceList.filter(a => a.status === 'absent').length;
    const late = attendanceList.filter(a => a.status === 'late').length;
    const excused = attendanceList.filter(a => a.status === 'excused').length;
    
    return {
      total,
      present,
      absent,
      late,
      excused,
      presentPercentage: total > 0 ? ((present / total) * 100).toFixed(1) : '0.0',
      absentPercentage: total > 0 ? ((absent / total) * 100).toFixed(1) : '0.0',
      latePercentage: total > 0 ? ((late / total) * 100).toFixed(1) : '0.0',
      excusedPercentage: total > 0 ? ((excused / total) * 100).toFixed(1) : '0.0'
    };
  }

  static translateStatus(status) {
    const translations = {
      'present': 'Présent',
      'absent': 'Absent',
      'late': 'En retard',
      'excused': 'Excusé'
    };
    return translations[status] || status;
  }
}

module.exports = PDFService;