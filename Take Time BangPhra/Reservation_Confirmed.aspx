<%@ Page Title="" Async="true" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Reservation_Confirmed.aspx.cs" Inherits="Take_Time_BangPhra.Reservation_Confirmed" %>
<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">
    <style type="text/css">
        body {
            background: linear-gradient(135deg, #6d4c41 0%, #8d6e63 100%);
            min-height: 100vh;
            padding: 10px;
            margin: 0;
        }

        .confirmation-container {
            font-family: 'Prompt', Arial, sans-serif;
            max-width: 1000px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            overflow: hidden;
            min-height: 90vh;
        }
        
        .confirmation-header {
            text-align: center;
            padding: 15px 20px;
            background: linear-gradient(135deg, #5d4037 0%, #8d6e63 100%);
            color: white;
        }
        
        .success-badge {
            background: #4caf50;
            color: white;
            padding: 6px 15px;
            border-radius: 15px;
            font-size: 0.9em;
            font-weight: bold;
            display: inline-block;
            margin-bottom: 8px;
        }
        
        .main-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 0;
            min-height: 500px;
        }
        
        .left-column {
            padding: 15px;
            background: #fafafa;
        }
        
        .right-column {
            padding: 15px;
            background: #f5f5f5;
            border-left: 2px solid #d7ccc8;
        }
        
        .info-card {
            background: white;
            padding: 12px;
            border-radius: 8px;
            margin-bottom: 10px;
            border-left: 3px solid #8d6e63;
            box-shadow: 0 2px 5px rgba(0,0,0,0.05);
        }
        
        .info-card h3 {
            color: #5d4037;
            margin: 0 0 8px 0;
            font-size: 0.9em;
            border-bottom: 1px solid #d7ccc8;
            padding-bottom: 5px;
        }
        
        .info-row {
            display: flex;
            justify-content: space-between;
            margin-bottom: 5px;
            padding: 3px 0;
            font-size: 0.8em;
        }
        
        .info-label {
            font-weight: bold;
            color: #5d4037;
            min-width: 100px;
        }
        
        .info-value {
            color: #333;
            text-align: right;
            flex: 1;
        }
        
        .payment-card {
            background: linear-gradient(135deg, #fff8e1 0%, #ffecb3 100%);
            padding: 10px;
            border-radius: 6px;
            border: 1px solid #ffd54f;
            margin: 8px 0;
        }
        
        .slip-card {
            background: white;
            padding: 12px;
            border-radius: 8px;
            text-align: center;
            margin-bottom: 10px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.05);
        }
        
        .slip-image {
            width: 100%;
            max-height: 120px;
            border-radius: 6px;
            border: 1px solid #d7ccc8;
            object-fit: contain;
            background: #f9f9f9;
        }
        
        .detail-card {
            background: white;
            padding: 10px;
            border-radius: 6px;
            margin-bottom: 8px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.05);
        }
        
        .detail-card h3 {
            color: #5d4037;
            margin: 0 0 6px 0;
            font-size: 0.85em;
            border-bottom: 1px solid #e0e0e0;
            padding-bottom: 3px;
        }
        
        .content-box {
            background: #f9f9f9;
            padding: 8px;
            border-radius: 4px;
            font-size: 0.75em;
            line-height: 1.3;
            max-height: 60px;
            overflow-y: auto;
        }
        
        .action-buttons {
            text-align: center;
            padding: 15px;
            background: white;
            border-top: 1px solid #d7ccc8;
        }
        
        .btn-receipt {
            background: linear-gradient(135deg, #4caf50 0%, #45a049 100%);
            color: white;
            padding: 8px 20px;
            border: none;
            border-radius: 15px;
            font-size: 0.8em;
            font-weight: bold;
            cursor: pointer;
            margin: 0 5px;
        }
        
        .btn-print {
            background: linear-gradient(135deg, #2196f3 0%, #1976d2 100%);
            color: white;
            padding: 8px 20px;
            border: none;
            border-radius: 15px;
            font-size: 0.8em;
            font-weight: bold;
            cursor: pointer;
            margin: 0 5px;
        }
        
        .instruction-text {
            text-align: center;
            color: rgba(255,255,255,0.9);
            font-size: 0.7em;
            margin-top: 5px;
        }
        
        .receipt-section {
            background: linear-gradient(135deg, #e8f5e8 0%, #f1f8e9 100%);
            padding: 8px;
            border-radius: 6px;
            border: 1px solid #c8e6c9;
            margin-top: 8px;
            font-size: 0.75em;
        }
        
        /* Custom scrollbar */
        .content-box::-webkit-scrollbar {
            width: 3px;
        }
        
        .content-box::-webkit-scrollbar-track {
            background: #f1f1f1;
        }
        
        .content-box::-webkit-scrollbar-thumb {
            background: #bcaaa4;
        }
        
        @media print {
            .action-buttons, .instruction-text {
                display: none;
            }
        }
        
        /* Mobile Optimization */
        @media (max-width: 768px) {
            body {
                padding: 5px;
            }
            
            .confirmation-container {
                border-radius: 10px;
                min-height: 95vh;
            }
            
            .confirmation-header {
                padding: 12px 15px;
            }
            
            .confirmation-header h1 {
                font-size: 1.2em;
                margin: 3px 0;
            }
            
            .success-badge {
                font-size: 0.8em;
                padding: 4px 12px;
            }
            
             .main-grid {
        grid-template-columns: 1fr 1fr;
        min-height: auto;
        gap: 0;
    }
    
    .right-column {
        border-left: 2px solid #d7ccc8;
        border-top: none;
    }
            
            .left-column, .right-column {
                padding: 12px;
            }
            
            .info-card, .slip-card, .detail-card {
                padding: 10px;
                margin-bottom: 8px;
                font-size: 0.75em;
            }
            
            .info-row {
                flex-direction: column;
                margin-bottom: 3px;
            }
            
            .info-label {
                min-width: auto;
                margin-bottom: 1px;
                font-size: 0.7em;
            }
            
            .info-value {
                text-align: left;
            }
            
            .slip-image {
                max-height: 100px;
            }
            
            .btn-receipt, .btn-print {
                padding: 6px 15px;
                font-size: 0.75em;
                margin: 2px;
            }
            
            .content-box {
                max-height: 45px;
                font-size: 0.7em;
            }
        }
        
        
        
        /* Compact mode for very small screens */
        @media (max-height: 700px) and (max-width: 768px) {
            .confirmation-container {
                min-height: 98vh;
            }
            
            .info-card, .slip-card, .detail-card {
                padding: 8px;
                margin-bottom: 6px;
            }
            
            .content-box {
                max-height: 40px;
                padding: 6px;
            }
            
            .slip-image {
                max-height: 80px;
            }
        }
    </style>
    <br /><br />
    <div class="confirmation-container">
        <!-- Header Section -->
        <div class="confirmation-header">
            <div class="success-badge">
                <asp:Label ID="Label10" runat="server" Text=""></asp:Label>
            </div>
            <h1 style="margin: 3px 0; font-size: 1.3em;">การยืนยันการจอง</h1>
            <p style="margin: 0; opacity: 0.9; font-size: 0.8em;">Reservation Confirmation</p>
            <div class="instruction-text">
                <strong>📱 กรุณาบันทึกภาพหน้าจอนี้เพื่อใช้ยืนยันในการลงทะเบียนเข้าพัก</strong>
            </div>
        </div>

        <div class="main-grid">
            <!-- Left Column -->
            <div class="left-column">
                <!-- Basic Information -->
                <div class="info-card">
                    <h3>📋 ข้อมูลการจอง</h3>
                    <div class="info-row">
                        <span class="info-label">รหัสการจอง:</span>
                        <span class="info-value"><asp:Label ID="Label1" runat="server" style="font-weight: bold; color: #d32f2f;"></asp:Label></span>
                    </div>
                    <div class="info-row">
                        <span class="info-label">ชื่อ-นามสกุล:</span>
                        <span class="info-value"><asp:Label ID="Label2" runat="server"></asp:Label></span>
                    </div>
                    <div class="info-row">
                        <span class="info-label">ชื่อเล่น:</span>
                        <span class="info-value"><asp:Label ID="Label3" runat="server"></asp:Label></span>
                    </div>
                    <div class="info-row">
                        <span class="info-label">เบอร์โทรศัพท์:</span>
                        <span class="info-value"><asp:Label ID="Label4" runat="server" style="font-family: monospace;"></asp:Label></span>
                    </div>
                </div>

                <!-- Stay Information -->
                <div class="info-card">
                    <h3>🏨 ข้อมูลการเข้าพัก</h3>
                    <div class="info-row">
                        <span class="info-label">วันที่เช็คอิน:</span>
                        <span class="info-value"><asp:Label ID="Label5" runat="server" style="color: #388e3c;"></asp:Label></span>
                    </div>
                    <div class="info-row">
                        <span class="info-label">วันที่เช็คเอาท์:</span>
                        <span class="info-value"><asp:Label ID="Label6" runat="server" style="color: #388e3c;"></asp:Label></span>
                    </div>
                    <div class="info-row">
                        <span class="info-label">จำนวนคืน:</span>
                        <span class="info-value"><asp:Label ID="Label7" runat="server"></asp:Label></span>
                    </div>
                </div>

                <!-- Payment Summary -->
                <div class="info-card">
                    <h3>💰 สรุปการชำระเงิน</h3>
                    <div class="payment-card">
                        <div class="info-row">
                            <span class="info-label">ราคารวมทั้งหมด:</span>
                            <span class="info-value" style="color: #d32f2f;">
                                ฿<asp:Label ID="Label11" runat="server" style="font-weight: bold;"></asp:Label>
                            </span>
                        </div>
                        <div class="info-row">
                            <span class="info-label">ยอดมัดจำที่ชำระแล้ว:</span>
                            <span class="info-value" style="color: #388e3c;">
                                ฿<asp:Label ID="Label12" runat="server" style="font-weight: bold;"></asp:Label>
                            </span>
                        </div>
                        <div class="info-row">
                            <span class="info-label">ยอดคงเหลือ:</span>
                            <span class="info-value" style="color: #f57c00; font-weight: bold;">
                                ฿<asp:Label ID="Label13" runat="server"></asp:Label>
                            </span>
                        </div>
                    </div>
                </div>

                <!-- Remark -->
                <div class="detail-card">
                    <h3>📝 หมายเหตุ</h3>
                    <div class="content-box" style="background: #fff3e0; border-left: 2px solid #ff9800;">
                        <asp:Label ID="Label14" runat="server" style="white-space: pre-line;"></asp:Label>
                    </div>
                </div>
            </div>

            <!-- Right Column -->
            <div class="right-column">
                <!-- Slip Image & Receipts -->
                <div class="slip-card">
                    <h3>📷 สลิปการโอนเงิน & ใบกำกับภาษี</h3>
                    <asp:Label ID="lblSlipCount" runat="server"
                        style="display: block; color: #4caf50; font-weight: bold; margin-bottom: 8px; font-size: 0.75em;"></asp:Label>

                    <asp:Repeater ID="rptPaymentSlips" runat="server">
                        <ItemTemplate>
                            <div style="margin-bottom: 8px; padding: 6px; background: #f5f5f5; border-radius: 4px; font-size: 0.75em;">
                                <div style="margin-bottom: 3px; font-size: 0.85em;">
                                    <strong>📅 วันที่:</strong> <%# Eval("PaymentDate", "{0:dd/MM/yyyy HH:mm}") %>
                                </div>
                                <div style="margin-bottom: 3px; font-size: 0.85em;">
                                    <strong>💰 จำนวน:</strong> <%# Eval("PaymentAmount", "{0:N2}") %> บาท
                                </div>
                                <div style="margin-bottom: 3px; font-size: 0.85em;">
                                    <strong>📝 ประเภท:</strong> <%# Eval("PaymentType") %>
                                </div>
                                <div>
                                    <a href='<%# ResolveUrl("~/" + Eval("SlipFileURL").ToString()) %>'
                                       target="_blank"
                                       style="color: #1976d2; text-decoration: none; font-weight: bold; font-size: 0.85em;">
                                        🔗 ดูสลิปการโอนเงิน
                                    </a>
                                </div>
                            </div>
                        </ItemTemplate>
                        <FooterTemplate>
                            <div style="color: #999; font-style: italic; margin-top: 8px; font-size: 0.75em;">
                                <%# (((System.Web.UI.WebControls.Repeater)Container.Parent).Items.Count == 0) ? "ไม่พบสลิปการโอนเงิน" : "" %>
                            </div>
                        </FooterTemplate>
                    </asp:Repeater>

                    <asp:Image ID="Image1" runat="server" CssClass="slip-image" Visible="false" />

                    <!-- Receipt Links Section -->
                    <asp:Panel ID="pnlReceiptLinks" runat="server" Visible="false"
                        style="margin-top: 10px; padding: 8px; background: linear-gradient(135deg, #e8f5e8 0%, #f1f8e9 100%); border-radius: 4px; border: 1px solid #c8e6c9;">
                        <div style="font-size: 0.75em; color: #2e7d32; font-weight: bold; margin-bottom: 5px;">
                            🧾 ใบกำกับภาษี
                        </div>
                        <asp:Repeater ID="rptReceipts" runat="server">
                            <ItemTemplate>
                                <div style="margin: 3px 0;">
                                    <a href='<%# GetReceiptPDFUrl(Eval("ID"), Eval("UID"), Eval("Created_Date")) %>'
                                       target="_blank"
                                       style="color: #4caf50; text-decoration: none; font-weight: bold; font-size: 0.8em;">
                                        📄 <%# Eval("ID") %> (<%# Eval("Total_Amount", "{0:N2}") %> บาท)
                                    </a>
                                </div>
                            </ItemTemplate>
                        </asp:Repeater>
                    </asp:Panel>

                    <p style="color: #666; margin: 5px 0 0 0; font-size: 0.7em;">
                        <em>หลักฐานการชำระเงิน</em>
                    </p>
                </div>

                <!-- Accommodation Details -->
                <div class="detail-card">
                    <h3>🛌 รายการที่พัก</h3>
                    <div class="content-box">
                        <asp:Label ID="Label8" runat="server" style="white-space: pre-line;"></asp:Label>
                    </div>
                </div>

                <!-- Rent Items and Product Charges -->
                <div class="detail-card">
                    <h3>🛍️ รายการของเช่า/สินค้า</h3>
                    <div class="content-box">
                        <asp:Label ID="Label9" runat="server" style="white-space: pre-line;"></asp:Label>
                    </div>
                </div>
            </div>
        </div>

        <!-- Action Buttons -->
        <div class="action-buttons">
            <button type="button" class="btn-print" onclick="captureAndDownload()">🖨️ บันทึกหน้านี้เป็นรูป</button>
        </div>
    </div>

    <!-- Include html2canvas library -->
    <script src="https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js"></script>

    <script>
        // Add some interactive effects
        document.addEventListener('DOMContentLoaded', function () {
            // Add fade-in animation to cards
            const cards = document.querySelectorAll('.info-card, .detail-card, .slip-card');
            cards.forEach((card, index) => {
                card.style.opacity = '0';
                card.style.transform = 'translateY(5px)';
                card.style.transition = 'all 0.3s ease';

                setTimeout(() => {
                    card.style.opacity = '1';
                    card.style.transform = 'translateY(0)';
                }, index * 50);
            });
        });

        // Capture and download page as image
        function captureAndDownload() {
            const element = document.querySelector('.confirmation-container');
            const buttons = document.querySelector('.action-buttons');

            // Hide buttons before capture
            if (buttons) buttons.style.display = 'none';

            // Show loading message
            const originalText = event.target.textContent;
            event.target.textContent = '⏳ กำลังสร้างรูป...';
            event.target.disabled = true;

            html2canvas(element, {
                scale: 2, // Higher quality
                useCORS: true,
                logging: false,
                backgroundColor: '#ffffff'
            }).then(canvas => {
                // Convert to image and download
                const link = document.createElement('a');
                const timestamp = new Date().getTime();
                link.download = 'การยืนยันการจอง_' + timestamp + '.png';
                link.href = canvas.toDataURL('image/png');
                link.click();

                // Restore buttons
                if (buttons) buttons.style.display = 'block';
                event.target.textContent = originalText;
                event.target.disabled = false;

                // Show success message
                alert('✅ บันทึกรูปเรียบร้อยแล้ว!');
            }).catch(error => {
                console.error('Error capturing page:', error);

                // Restore buttons
                if (buttons) buttons.style.display = 'block';
                event.target.textContent = originalText;
                event.target.disabled = false;

                alert('❌ เกิดข้อผิดพลาดในการบันทึกรูป กรุณาลองใหม่อีกครั้ง');
            });
        }
    </script>
</asp:Content>