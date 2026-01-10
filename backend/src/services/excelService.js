const ExcelJS = require('exceljs');

class ExcelService {
  // Générer un fichier Excel pour un examen
  static async generateExamExcel(exam, attendanceList) {
    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet('Feuille de présence');
    
    // Titre
    worksheet.mergeCells('A1:F1');
    worksheet.getCell('A1').value = 'FEUILLE DE PRÉSENCE - ' + exam.name.toUpperCase();
    worksheet.getCell('A1').font = { bold: true, size: 16 };
    worksheet.getCell('A1').alignment = { horizontal: 'center' };
    
    // Informations examen
    worksheet.mergeCells('A3:F3');
    worksheet.getCell('A3').value = 'INFORMATIONS EXAMEN';
    worksheet.getCell('A3').font = { bold: true };
    
    worksheet.getCell('A4').value = 'Date:';
    worksheet.getCell('B4').value = new Date(exam.exam_date).toLocaleDateString('fr-FR');
    
    worksheet.getCell('A5').value = 'Heure:';
    worksheet.getCell('B5').value = `${exam.start_time} - ${exam.end_time}`;
    
    worksheet.getCell('A6').value = 'Salle:';
    worksheet.getCell('B6').value = exam.room_name || 'N/A';
    
    worksheet.getCell('A7').value = 'Surveillant:';
    worksheet.getCell('B7').value = exam.supervisor_name || 'N/A';
    
    // Statistiques
    worksheet.mergeCells('D4:F4');
    worksheet.getCell('D4').value = 'STATISTIQUES';
    worksheet.getCell('D4').font = { bold: true };
    
    const stats = this.calculateStats(attendanceList);
    const statsData = [
      ['Total étudiants', stats.total],
      ['Présents', `${stats.present} (${stats.presentPercentage}%)`],
      ['Absents', `${stats.absent} (${stats.absentPercentage}%)`],
      ['En retard', `${stats.late} (${stats.latePercentage}%)`],
      ['Excusés', `${stats.excused} (${stats.excusedPercentage}%)`]
    ];
    
    statsData.forEach((row, index) => {
      worksheet.getCell(`D${5 + index}`).value = row[0];
      worksheet.getCell(`E${5 + index}`).value = row[1];
    });
    
    // En-tête du tableau
    worksheet.mergeCells('A9:F9');
    worksheet.getCell('A9').value = 'LISTE DES PRÉSENCES';
    worksheet.getCell('A9').font = { bold: true };
    
    const headers = ['N°', 'Code étudiant', 'Nom', 'Prénom', 'Statut', 'Heure validation'];
    worksheet.addRow(headers);
    
    const headerRow = worksheet.getRow(10);
    headerRow.font = { bold: true };
    headerRow.eachCell(cell => {
      cell.fill = {
        type: 'pattern',
        pattern: 'solid',
        fgColor: { argb: 'FFE0E0E0' }
      };
      cell.border = {
        top: { style: 'thin' },
        left: { style: 'thin' },
        bottom: { style: 'thin' },
        right: { style: 'thin' }
      };
    });
    
    // Données
    attendanceList.forEach((att, index) => {
      const row = worksheet.addRow([
        index + 1,
        att.student_code,
        att.last_name,
        att.first_name,
        this.translateStatus(att.status),
        att.validation_time ? new Date(att.validation_time).toLocaleString('fr-FR') : 'N/A'
      ]);
      
      // Couleur selon le statut
      let color;
      switch(att.status) {
        case 'present': color = 'FFC6EFCE'; break; // Vert clair
        case 'absent': color = 'FFFFC7CE'; break; // Rouge clair
        case 'late': color = 'FFFFEB9C'; break; // Jaune
        case 'excused': color = 'FFD9D9D9'; break; // Gris
        default: color = 'FFFFFFFF';
      }
      
      row.eachCell(cell => {
        cell.fill = {
          type: 'pattern',
          pattern: 'solid',
          fgColor: { argb: color }
        };
        cell.border = {
          top: { style: 'thin' },
          left: { style: 'thin' },
          bottom: { style: 'thin' },
          right: { style: 'thin' }
        };
      });
    });
    
    // Ajuster la largeur des colonnes
    worksheet.columns = [
      { width: 10 }, // N°
      { width: 15 }, // Code
      { width: 25 }, // Nom
      { width: 25 }, // Prénom
      { width: 15 }, // Statut
      { width: 25 }  // Heure
    ];
    
    // Ajouter une feuille de résumé
    this.addSummarySheet(workbook, exam, stats);
    
    // Générer le buffer
    const buffer = await workbook.xlsx.writeBuffer();
    return buffer;
  }

  static addSummarySheet(workbook, exam, stats) {
    const summarySheet = workbook.addWorksheet('Résumé');
    
    // Titre
    summarySheet.mergeCells('A1:D1');
    summarySheet.getCell('A1').value = 'RAPPORT D\'EXAMEN - ' + exam.name;
    summarySheet.getCell('A1').font = { bold: true, size: 14 };
    summarySheet.getCell('A1').alignment = { horizontal: 'center' };
    
    // Informations
    summarySheet.getCell('A3').value = 'Date de génération:';
    summarySheet.getCell('B3').value = new Date().toLocaleString('fr-FR');
    
    summarySheet.getCell('A4').value = 'Examen:';
    summarySheet.getCell('B4').value = exam.name;
    
    summarySheet.getCell('A5').value = 'Date examen:';
    summarySheet.getCell('B5').value = new Date(exam.exam_date).toLocaleDateString('fr-FR');
    
    // Graphique des statistiques (données)
    summarySheet.getCell('A7').value = 'DÉTAIL DES STATISTIQUES';
    summarySheet.getCell('A7').font = { bold: true };
    
    const statsData = [
      ['Statut', 'Nombre', 'Pourcentage'],
      ['Présents', stats.present, `${stats.presentPercentage}%`],
      ['Absents', stats.absent, `${stats.absentPercentage}%`],
      ['En retard', stats.late, `${stats.latePercentage}%`],
      ['Excusés', stats.excused, `${stats.excusedPercentage}%`],
      ['TOTAL', stats.total, '100%']
    ];
    
    statsData.forEach((row, rowIndex) => {
      row.forEach((cell, colIndex) => {
        const cellRef = summarySheet.getCell(rowIndex + 8, colIndex + 1);
        cellRef.value = cell;
        
        if (rowIndex === 0) {
          cellRef.font = { bold: true };
          cellRef.fill = {
            type: 'pattern',
            pattern: 'solid',
            fgColor: { argb: 'FFE0E0E0' }
          };
        }
      });
    });
    
    // Ajuster largeurs
    summarySheet.columns = [
      { width: 20 },
      { width: 15 },
      { width: 15 }
    ];
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

module.exports = ExcelService;