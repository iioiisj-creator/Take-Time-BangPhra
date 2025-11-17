using System;
using System.Data;
using System.IO;
using System.Web;
using System.Drawing;
using System.Drawing.Imaging;

namespace Take_Time_BangPhra
{
    /// <summary>
    /// Product Service - Business logic for products and images
    /// </summary>
    public class ProductService
    {
        private readonly string _connectionString;
        private readonly ProductDataAccess _productDA;
        private readonly code _code;

        public ProductService(string connectionString)
        {
            _connectionString = connectionString;
            _productDA = new ProductDataAccess(connectionString);
            _code = new code();
        }

        /// <summary>
        /// Upload product image
        /// </summary>
        public long UploadProductImage(
            string productType,
            int productId,
            HttpPostedFile imageFile,
            string caption = null,
            bool isMainImage = false,
            int? adminId = null)
        {
            // Validate
            if (imageFile == null || imageFile.ContentLength == 0)
                throw new Exception("ไม่มีไฟล์");

            string ext = Path.GetExtension(imageFile.FileName).ToLower();
            if (ext != ".jpg" && ext != ".jpeg" && ext != ".png")
                throw new Exception("รองรับเฉพาะ JPG/PNG");

            if (imageFile.ContentLength > 10 * 1024 * 1024) // 10MB
                throw new Exception("ไฟล์ใหญ่เกิน (สูงสุด 10MB)");

            // Generate filename
            string fileName = string.Format("{0}_{1}_{2}{3}", productType, productId, Guid.NewGuid():N, ext);
            string thumbFileName = string.Format("{0}_{1}_{2}_thumb{3}", productType, productId, Guid.NewGuid():N, ext);

            // Save paths
            string uploadDir = HttpContext.Current.Server.MapPath(string.Format("~/Images/{0}/{1}/", productType, productId));
            if (!Directory.Exists(uploadDir))
                Directory.CreateDirectory(uploadDir);

            string fullPath = Path.Combine(uploadDir, fileName);
            string thumbPath = Path.Combine(uploadDir, thumbFileName);

            // Save original
            imageFile.SaveAs(fullPath);

            // Create thumbnail
            CreateThumbnail(fullPath, thumbPath, 300, 200);

            // Get next order
            int nextOrder = GetNextImageOrder(productType, productId);

            // Insert to DB
            long imageId = _productDA.InsertProductImage(
                productType,
                productId,
                string.Format("~/Images/{0}/{1}/{2}", productType, productId, fileName),
                string.Format("~/Images/{0}/{1}/{2}", productType, productId, thumbFileName),
                nextOrder,
                isMainImage,
                caption,
                adminId
            );

            // If main image, unset others
            if (isMainImage)
            {
                UnsetOtherMainImages(productType, productId, imageId);
            }

            return imageId;
        }

        /// <summary>
        /// Create thumbnail image
        /// </summary>
        private void CreateThumbnail(string sourcePath, string destPath, int maxWidth, int maxHeight)
        {
            using (Image original = Image.FromFile(sourcePath))
            {
                // Calculate dimensions
                int width = original.Width;
                int height = original.Height;
                float ratio = Math.Min((float)maxWidth / width, (float)maxHeight / height);

                int newWidth = (int)(width * ratio);
                int newHeight = (int)(height * ratio);

                // Create thumbnail
                using (Bitmap thumbnail = new Bitmap(newWidth, newHeight))
                {
                    using (Graphics g = Graphics.FromImage(thumbnail))
                    {
                        g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
                        g.DrawImage(original, 0, 0, newWidth, newHeight);
                    }

                    // Save
                    thumbnail.Save(destPath, ImageFormat.Jpeg);
                }
            }
        }

        /// <summary>
        /// Get next image order number
        /// </summary>
        private int GetNextImageOrder(string productType, int productId)
        {
            var images = _productDA.GetProductImages(productType, productId);
            return images.Rows.Count + 1;
        }

        /// <summary>
        /// Unset other main images
        /// </summary>
        private void UnsetOtherMainImages(string productType, int productId, long excludeImageId)
        {
            _code.DatabaseInsertSafe(_connectionString,
                $@"UPDATE Product_Images
                   SET IsMainImage = 0
                   WHERE ProductType = '{productType}'
                   AND Product_ID = {productId}
                   AND ID != {excludeImageId}",
                null);
        }

        /// <summary>
        /// Get product images
        /// </summary>
        public DataTable GetProductImages(string productType, int productId)
        {
            return _productDA.GetProductImages(productType, productId);
        }

        /// <summary>
        /// Get main image URL
        /// </summary>
        public string GetMainImageUrl(string productType, int productId)
        {
            var image = _productDA.GetMainImage(productType, productId);
            if (image.Rows.Count > 0)
            {
                return image.Rows[0]["ImageURL"].ToString();
            }
            return "~/Images/placeholder.jpg";
        }
    }
}
