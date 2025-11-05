using System;
using System.Collections.Generic;
using System.Data;
using System.Drawing;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using Tesseract;

namespace Take_Time_BangPhra.Services
{
    /// <summary>
    /// OCR Service for extracting payment amount from slip images
    /// Supports Thai bank slips from mobile apps, ATM, and branch transfers
    /// </summary>
    public class SlipOCRService
    {
        private readonly string _tessDataPath;
        private readonly string _connectionString;

        public SlipOCRService(string tessDataPath, string connectionString)
        {
            _tessDataPath = tessDataPath;
            _connectionString = connectionString;
        }

        /// <summary>
        /// Result of OCR processing
        /// </summary>
        public class OCRResult
        {
            public bool Success { get; set; }
            public decimal? Amount { get; set; }
            public double Confidence { get; set; }
            public string RawText { get; set; }
            public string ErrorMessage { get; set; }
            public string Status { get; set; } // SUCCESS, FAILED, MANUAL_REVIEW

            public OCRResult()
            {
                Success = false;
                Amount = null;
                Confidence = 0;
                RawText = "";
                ErrorMessage = "";
                Status = "FAILED";
            }
        }

        /// <summary>
        /// Process slip image and extract payment amount
        /// </summary>
        public OCRResult ProcessSlip(string imageFilePath)
        {
            var result = new OCRResult();

            try
            {
                // Validate file exists
                if (!File.Exists(imageFilePath))
                {
                    result.ErrorMessage = "ไม่พบไฟล์รูปภาพ";
                    result.Status = "FAILED";
                    return result;
                }

                // Perform OCR
                string extractedText = PerformOCR(imageFilePath);
                result.RawText = extractedText;

                if (string.IsNullOrWhiteSpace(extractedText))
                {
                    result.ErrorMessage = "ไม่สามารถอ่านข้อความจากรูปภาพได้";
                    result.Status = "FAILED";
                    return result;
                }

                // Extract amount from text
                var amountExtractionResult = ExtractAmountFromText(extractedText);

                if (amountExtractionResult.Amount.HasValue)
                {
                    result.Amount = amountExtractionResult.Amount;
                    result.Confidence = amountExtractionResult.Confidence;
                    result.Success = true;

                    // Determine status based on confidence
                    if (result.Confidence >= 70)
                    {
                        result.Status = "SUCCESS";
                    }
                    else
                    {
                        result.Status = "MANUAL_REVIEW"; // Low confidence
                        result.ErrorMessage = "ความมั่นใจต่ำ ต้องตรวจสอบด้วยตนเอง";
                    }
                }
                else
                {
                    result.ErrorMessage = "ไม่พบจำนวนเงินในสลิป";
                    result.Status = "MANUAL_REVIEW";
                }
            }
            catch (Exception ex)
            {
                result.ErrorMessage = $"เกิดข้อผิดพลาดในการประมวลผล: {ex.Message}";
                result.Status = "FAILED";
            }

            return result;
        }

        /// <summary>
        /// Perform OCR using Tesseract with Thai + English languages
        /// </summary>
        private string PerformOCR(string imageFilePath)
        {
            try
            {
                // Preprocess image for better OCR results
                using (var preprocessedImage = PreprocessImage(imageFilePath))
                {
                    using (var engine = new TesseractEngine(_tessDataPath, "tha+eng", EngineMode.Default))
                    {
                        // Configure for better accuracy
                        engine.SetVariable("tessedit_char_whitelist", "0123456789.,฿บาทBahtTHB ");

                        using (var img = PixConverter.ToPix(preprocessedImage))
                        {
                            using (var page = engine.Process(img))
                            {
                                return page.GetText();
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                throw new Exception($"OCR processing failed: {ex.Message}", ex);
            }
        }

        /// <summary>
        /// Preprocess image for better OCR accuracy
        /// - Convert to grayscale
        /// - Increase contrast
        /// - Resize if too small
        /// </summary>
        private Bitmap PreprocessImage(string imageFilePath)
        {
            using (var original = new Bitmap(imageFilePath))
            {
                // Create new bitmap
                var processed = new Bitmap(original.Width, original.Height);

                using (var g = Graphics.FromImage(processed))
                {
                    // High quality rendering
                    g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
                    g.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.HighQuality;
                    g.PixelOffsetMode = System.Drawing.Drawing2D.PixelOffsetMode.HighQuality;
                    g.CompositingQuality = System.Drawing.Drawing2D.CompositingQuality.HighQuality;

                    // Draw original
                    g.DrawImage(original, 0, 0, original.Width, original.Height);
                }

                // Convert to grayscale and increase contrast
                for (int y = 0; y < processed.Height; y++)
                {
                    for (int x = 0; x < processed.Width; x++)
                    {
                        Color pixel = processed.GetPixel(x, y);

                        // Grayscale
                        int gray = (int)(pixel.R * 0.3 + pixel.G * 0.59 + pixel.B * 0.11);

                        // Increase contrast (simple thresholding)
                        gray = gray > 128 ? 255 : 0;

                        Color newColor = Color.FromArgb(gray, gray, gray);
                        processed.SetPixel(x, y, newColor);
                    }
                }

                return processed;
            }
        }

        /// <summary>
        /// Extract amount from OCR text using multiple patterns
        /// Supports various Thai bank slip formats
        /// </summary>
        private (decimal? Amount, double Confidence) ExtractAmountFromText(string text)
        {
            if (string.IsNullOrWhiteSpace(text))
                return (null, 0);

            // List of regex patterns for different slip formats
            var patterns = new List<(Regex Pattern, int Priority)>
            {
                // Pattern 1: "จำนวนเงิน 1,234.56 บาท" or "Amount 1,234.56 Baht"
                (new Regex(@"(?:จำนวนเงิน|Amount|ยอดเงิน|จ่าย)[\s:]*([0-9,]+\.?\d{0,2})[\s]*(?:บาท|Baht|THB)?",
                    RegexOptions.IgnoreCase), 90),

                // Pattern 2: "฿1,234.56" or "THB 1,234.56"
                (new Regex(@"(?:฿|THB|Baht)[\s]*([0-9,]+\.?\d{0,2})",
                    RegexOptions.IgnoreCase), 85),

                // Pattern 3: Standalone number with comma and decimal "1,234.56"
                (new Regex(@"\b([0-9]{1,3}(?:,[0-9]{3})*\.?\d{0,2})\b"), 80),

                // Pattern 4: Number without comma "1234.56"
                (new Regex(@"\b([0-9]+\.\d{2})\b"), 70),

                // Pattern 5: Number with "บาท" after
                (new Regex(@"([0-9,]+\.?\d{0,2})[\s]*บาท"), 85),
            };

            var foundAmounts = new List<(decimal Amount, int Priority)>();

            foreach (var (pattern, priority) in patterns)
            {
                var matches = pattern.Matches(text);

                foreach (Match match in matches)
                {
                    if (match.Groups.Count > 1)
                    {
                        string amountStr = match.Groups[1].Value.Replace(",", "").Trim();

                        if (decimal.TryParse(amountStr, NumberStyles.Number, CultureInfo.InvariantCulture, out decimal amount))
                        {
                            // Validate amount range (0.01 - 1,000,000)
                            if (amount >= 0.01m && amount <= 1000000m)
                            {
                                foundAmounts.Add((amount, priority));
                            }
                        }
                    }
                }
            }

            if (foundAmounts.Count == 0)
                return (null, 0);

            // Get highest priority amount
            var bestMatch = foundAmounts.OrderByDescending(x => x.Priority).First();

            // Calculate confidence based on:
            // - Pattern priority (70-90%)
            // - Number of matches (if multiple patterns found same amount: +10%)
            double confidence = bestMatch.Priority;

            var duplicateMatches = foundAmounts.Count(x => x.Amount == bestMatch.Amount);
            if (duplicateMatches > 1)
            {
                confidence = Math.Min(100, confidence + 10);
            }

            return (bestMatch.Amount, confidence);
        }

        /// <summary>
        /// Save OCR result to database
        /// </summary>
        public void SaveOCRResult(long slipId, OCRResult result)
        {
            try
            {
                var code2 = new code2();
                var conn = _connectionString;

                string query = @"
                    UPDATE Payment_Slips
                    SET OCR_Amount = @Amount,
                        OCR_Status = @Status,
                        OCR_Confidence = @Confidence,
                        OCR_RawText = @RawText,
                        OCR_ErrorMessage = @ErrorMessage,
                        OCR_ProcessedDate = GETDATE()
                    WHERE ID = @SlipId";

                var parameters = new Dictionary<string, object>
                {
                    { "@SlipId", slipId },
                    { "@Amount", result.Amount.HasValue ? (object)result.Amount.Value : DBNull.Value },
                    { "@Status", result.Status },
                    { "@Confidence", result.Confidence },
                    { "@RawText", result.RawText ?? "" },
                    { "@ErrorMessage", result.ErrorMessage ?? "" }
                };

                code2.DatabaseExecuteSafe(conn, query, parameters);
            }
            catch (Exception ex)
            {
                // Log error
                var code2 = new code2();
                code2.Logs(_connectionString, "SlipOCRService.SaveOCRResult Error",
                    $"SlipID: {slipId}, Error: {ex.Message}", "SYSTEM");
            }
        }

        /// <summary>
        /// Verify if OCR amount matches declared amount
        /// Returns true if amounts match within tolerance
        /// </summary>
        public bool VerifyAmount(decimal ocrAmount, decimal declaredAmount, decimal tolerancePercent = 0)
        {
            if (tolerancePercent == 0)
            {
                // Exact match required
                return ocrAmount == declaredAmount;
            }

            // Allow tolerance
            decimal tolerance = declaredAmount * (tolerancePercent / 100);
            decimal lowerBound = declaredAmount - tolerance;
            decimal upperBound = declaredAmount + tolerance;

            return ocrAmount >= lowerBound && ocrAmount <= upperBound;
        }

        /// <summary>
        /// Get pending OCR slips (for batch processing)
        /// </summary>
        public DataTable GetPendingOCRSlips(int limit = 50)
        {
            try
            {
                var code2 = new code2();
                var conn = _connectionString;

                string query = @"
                    SELECT TOP (@Limit)
                        ID,
                        SlipFileURL,
                        Account_Receipt_ID,
                        Reservation_ID
                    FROM Payment_Slips
                    WHERE OCR_Status = 'PENDING'
                      AND IsActive = 1
                      AND Status = 1
                    ORDER BY UploadedDate ASC";

                var parameters = new Dictionary<string, object>
                {
                    { "@Limit", limit }
                };

                return code2.DatabaseQuerySafe(conn, query, parameters);
            }
            catch (Exception ex)
            {
                var code2 = new code2();
                code2.Logs(_connectionString, "SlipOCRService.GetPendingOCRSlips Error",
                    $"Error: {ex.Message}", "SYSTEM");
                return new DataTable();
            }
        }
    }
}
