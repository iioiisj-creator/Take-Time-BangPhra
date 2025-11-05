<%@ Page Title="รายการผู้เข้าพักรายวัน" Language="C#" Async="True" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="ReserveTable.aspx.cs" Inherits="Take_Time_BangPhra.ReserveTable" %>
<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
    <link rel="stylesheet" href="/Content/jquery-ui.css">
    <link rel="stylesheet" href="/Content/style.css">
    <link rel="stylesheet" type="text/css" href="/Content/GridView2.css">
    
    <style type="text/css">
        .wrap { white-space: normal; width: 100px; }
        th, td { padding: 5px; }
        .header-center { text-align: center; }
        .header-right { text-align: right; }
        .print-only { display: none; }
        .no-print { display: block; }
        .hidden { display: none; }
        
        @media print {
            @page {
                margin: 0.2cm;
                size: landscape;
            }
            body {
                margin: 0.2cm;
                padding: 0;
            }
            .no-print { display: none !important; }
            .print-only { display: table-cell !important; }
            .print-header { display: table-cell !important; }
            .jumbotron { padding: 10px !important; margin: 0 !important; }
            .mydatagrid {
                border: 1px solid #000 !important;
                width: 100%;
                border-collapse: collapse;
            }
            .mydatagrid th, .mydatagrid td {
                border: 1px solid #000 !important;
                padding: 3px !important;
                vertical-align: top;
            }
            .mydatagrid td {
                height: 74px !important;
            }
            /* ปรับความกว้างคอลัมน์สำหรับ print */
            .mydatagrid th:nth-child(1), .mydatagrid td:nth-child(1) { width: 3%; }
            .mydatagrid th:nth-child(2), .mydatagrid td:nth-child(2) { width: 14%; }
            .mydatagrid th:nth-child(3), .mydatagrid td:nth-child(3) { width: 10%; } /* รายชื่อห้องพัก - แคบลง */
            .mydatagrid th:nth-child(4), .mydatagrid td:nth-child(4) { width: 3%; }
            .mydatagrid th:nth-child(5), .mydatagrid td:nth-child(5) { width: 24%; } /* รายการของเช่า - กว้างขึ้น */
            .mydatagrid th:nth-child(6), .mydatagrid td:nth-child(6) { width: 4%; }
            .mydatagrid th:nth-child(7), .mydatagrid td:nth-child(7) { width: 4%; }
            .mydatagrid th:nth-child(8), .mydatagrid td:nth-child(8) { width: 4%; }
            .mydatagrid th:nth-child(9), .mydatagrid td:nth-child(9) { width: 10%; } /* หมายเหตุ - แคบลง */
        }
        
        .action-buttons { margin: 10px 0; }
        .calendar-container { margin-bottom: 20px; }
        .legend { font-size: 12px; margin: 10px 0; }
        .legend-red { color: red; font-weight: bold; }
        .btn-group-vertical .btn { margin-bottom: 2px; }
        .calendar-style { font-size: 14px; }
    </style>

    <div class="container-fluid">
        <div class="row">
            <div class="col-md-12">
                <h2 class="text-center"><strong>รายการผู้เข้าพักรายวัน</strong></h2>
                
                <div class="action-buttons no-print text-right mb-3">
                    <asp:Button ID="btnPrint" runat="server" Text="พิมพ์ตารางรายวัน" 
                        CssClass="btn btn-primary" OnClientClick="printTable(); return false;" />
                </div>

                <div class="calendar-container">
                    <div class="card">
                        <div class="card-body">
                            <center>
                                <asp:Calendar ID="Calendar1" runat="server" Height="199px" Width="80%" 
                                    OnDayRender="Calendar1_DayRender" OnSelectionChanged="Calendar1_SelectionChanged"
                                    CssClass="calendar-style"></asp:Calendar>
                            </center>
                            
                            <div class="legend text-center">
                                <span class="legend-red">ตัวหนังสือสีแดง</span> คือ ห้องพักทั้งหมดเต็ม
                            </div>
                        </div>
                    </div>
                </div>

                <div class="table-container">
                    <center>
                        <asp:Label ID="Label1" runat="server" Text="" CssClass="h4 text-primary mb-3"></asp:Label>
                        
                        <asp:GridView ID="GridView1" DataKeyNames="ID" runat="server" 
                            AutoGenerateColumns="False" CssClass="mydatagrid table-responsive"
                            HeaderStyle-CssClass="header" RowStyle-CssClass="rows" PagerStyle-CssClass="pager"
                            BorderStyle="Solid" OnRowCommand="GridView1_RowCommand">
                            <Columns>
                                <asp:TemplateField HeaderText="เคยมาแล้ว" HeaderStyle-Width="4%" HeaderStyle-CssClass="header-center">
                                    <ItemTemplate>
                                        <asp:Button ID="Button6" runat="server" Text='<%# Eval("CountReserved") + " ครั้ง" %>' 
                                            CommandArgument='<%# Eval("ID") %>' CommandName="CountReserved" 
                                            CssClass="btn btn-info btn-sm no-print" OnClientClick="aspnetForm.target ='_blank';"/>
                                        <span class="print-only" data-count='<%# Eval("CountReserved") %>'><%# Eval("CountReserved") %> ครั้ง</span>
                                    </ItemTemplate>
                                    <HeaderStyle Width="4%" CssClass="header-center" />
                                </asp:TemplateField>

                                <asp:BoundField DataField="Name" HeaderText="ชื่อผู้จอง" 
                                    HeaderStyle-Width="12%" HeaderStyle-CssClass="header-center" />

                                <asp:BoundField DataField="AccomName" HeaderText="รายชื่อห้องพัก" 
                                    HeaderStyle-Width="15%" HeaderStyle-CssClass="header-center" />

                                <asp:BoundField DataField="StayDays" HeaderText="จำนวนคืน" 
                                    HeaderStyle-Width="5%" HeaderStyle-CssClass="header-center" 
                                    ItemStyle-CssClass="header-center" />

                                <asp:BoundField DataField="Items" HeaderText="รายการของเช่า" 
                                    HeaderStyle-Width="15%" HeaderStyle-CssClass="header-center" />

                                <asp:BoundField DataField="TotalPrice" HeaderText="ราคาทั้งหมด" 
                                    HeaderStyle-Width="6%" HeaderStyle-CssClass="header-center" 
                                    ItemStyle-CssClass="header-center" 
                                    DataFormatString="{0:N0}" HtmlEncode="false" />

                                <asp:BoundField DataField="Deposit" HeaderText="ยอดเงินรับมา" 
                                    HeaderStyle-Width="6%" HeaderStyle-CssClass="header-center" 
                                    ItemStyle-CssClass="header-center" 
                                    DataFormatString="{0:N0}" HtmlEncode="false" />

                                <asp:BoundField DataField="Remain" HeaderText="ส่วนที่เหลือ" 
                                    HeaderStyle-Width="6%" HeaderStyle-CssClass="header-center" 
                                    ItemStyle-CssClass="header-center" 
                                    DataFormatString="{0:N0}" HtmlEncode="false" />

                                <asp:BoundField DataField="Remark" HeaderText="หมายเหตุ" 
                                    HeaderStyle-Width="10%" HeaderStyle-CssClass="header-center" />

                                <asp:BoundField DataField="Reserve_By" HeaderText="จองโดย" 
                                    HeaderStyle-Width="6%" HeaderStyle-CssClass="header-center" 
                                    ItemStyle-CssClass="header-center" />

                                <asp:BoundField DataField="Status" HeaderText="สถานะ" 
                                    HeaderStyle-Width="6%" HeaderStyle-CssClass="header-center" 
                                    ItemStyle-CssClass="header-center" />

                                <asp:TemplateField HeaderText="ดำเนินการ" HeaderStyle-Width="15%" HeaderStyle-CssClass="header-center">
                                    <ItemTemplate>
                                        <div class="btn-group-vertical btn-group-sm no-print">
                                            <asp:Button ID="Button1" runat="server" Text="เช็คอิน" 
                                                CommandArgument='<%# Eval("ID") %>' CommandName="Checkin"
                                                CssClass="btn btn-success btn-sm mb-1" 
                                                onclientclick="return confirm('ยืนยันการเช็คอินหรือไม่');"/>
                                            
                                            <asp:Button ID="Button2" runat="server" Text="แก้ไข" 
                                                CommandArgument='<%# Eval("ID") %>' CommandName="EditReservation"
                                                CssClass="btn btn-warning btn-sm mb-1" />
                                            
                                            <asp:Button ID="Button3" runat="server" Text="ยกเลิกไม่คืนเงิน" 
                                                CommandArgument='<%# Eval("ID") %>' CommandName="CancelNoRefund"
                                                CssClass="btn btn-danger btn-sm mb-1" 
                                                onclientclick="return confirm('ยืนยันการยกเลิกไม่คืนเงินหรือไม่');"/>
                                            
                                            <asp:Button ID="Button4" runat="server" Text="ยกเลิกคืนเงิน" 
                                                CommandArgument='<%# Eval("ID") %>' CommandName="CancelRefund"
                                                CssClass="btn btn-secondary btn-sm mb-1" 
                                                onclientclick="return confirm('ยืนยันการยกเลิกคืนเงินหรือไม่');"/>
                                            
                                            <asp:Button ID="Button5" runat="server" Text="เช่าเพิ่ม"
                                                CommandArgument='<%# Eval("ID") %>' CommandName="RentMore"
                                                CssClass="btn btn-info btn-sm mb-1" />

                                            <asp:Button ID="btnPayMore" runat="server" Text="จ่ายเงินเพิ่ม"
                                                CommandArgument='<%# Eval("ID") %>' CommandName="PayMore"
                                                CssClass="btn btn-success btn-sm mb-1" />

                                            <asp:Button ID="btnCheckout" runat="server" Text="เช็คเอาท์"
                                                CommandArgument='<%# Eval("ID") %>' CommandName="Checkout"
                                                CssClass="btn btn-danger btn-sm mb-1"
                                                OnClientClick="return confirm('ยืนยันการเช็คเอาท์หรือไม่');" />

                                            <asp:Button ID="Button7" runat="server" Text="รายละเอียด"
                                                CommandArgument='<%# Container.DataItemIndex %>' CommandName="Detail"
                                                CssClass="btn btn-primary btn-sm" />
                                        </div>
                                        <div class="print-only">
                                            &nbsp;
                                        </div>
                                    </ItemTemplate>
                                    <HeaderStyle Width="15%" CssClass="header-center" />
                                </asp:TemplateField>

                                <asp:TemplateField HeaderText="" HeaderStyle-CssClass="hidden print-header">
                                    <ItemTemplate>
                                        <div class="print-only">
                                            &nbsp;
                                        </div>
                                    </ItemTemplate>
                                    <HeaderStyle CssClass="hidden print-header" />
                                    <ItemStyle CssClass="hidden print-only" />
                                </asp:TemplateField>

                                <asp:TemplateField HeaderText="" HeaderStyle-CssClass="hidden print-header">
                                    <ItemTemplate>
                                        <div class="print-only">
                                            &nbsp;
                                        </div>
                                    </ItemTemplate>
                                    <HeaderStyle CssClass="hidden print-header" />
                                    <ItemStyle CssClass="hidden print-only" />
                                </asp:TemplateField>

                                <asp:BoundField DataField="ID" HeaderText="หมายเลขการจอง" 
                                    HeaderStyle-CssClass="hidden" ItemStyle-CssClass="hidden" />
                            </Columns>

                            <HeaderStyle CssClass="header" />
                            <PagerStyle CssClass="pager" />
                            <RowStyle CssClass="rows" />
                        </asp:GridView>
                    </center>
                </div>
            </div>
        </div>
    </div>

    <script type="text/javascript">
        function printTable() {
            // Detect if device is mobile/Android
            var isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
            var isAndroid = /Android/i.test(navigator.userAgent);

            // For Android/Mobile devices, use alternative print method
            if (isMobile) {
                // Hide non-print elements
                var noPrintElements = document.querySelectorAll('.no-print');
                noPrintElements.forEach(function(el) {
                    el.style.display = 'none';
                });

                // Show print-only elements
                var printElements = document.querySelectorAll('.print-only');
                printElements.forEach(function(el) {
                    el.style.display = 'table-cell';
                });

                // Use direct print
                window.print();

                // Restore display after print
                setTimeout(function() {
                    noPrintElements.forEach(function(el) {
                        el.style.display = '';
                    });
                    printElements.forEach(function(el) {
                        el.style.display = '';
                    });
                }, 100);

                return;
            }

            // Desktop/iOS - use popup window method
            var originalContents = document.body.innerHTML;

            var printWindow = window.open('', '_blank', 'width=1200,height=800');

            if (!printWindow) {
                alert('กรุณาอนุญาตให้เปิด popup window เพื่อพิมพ์ตาราง');
                return;
            }

            var tableHTML = '<table style="width: 100%; border-collapse: collapse; font-size: 10px; border: 1px solid #000; margin: 0; padding: 0;">';

            var headerRow = document.querySelector('.mydatagrid .header');
            if (headerRow) {
                tableHTML += '<thead><tr style="background-color: #f2f2f2; height: 25px;">';

                // ปรับความกว้างคอลัมน์: ลด รายชื่อห้องพัก และ หมายเหตุ, เพิ่ม รายการของเช่า
                tableHTML += '<th style="border: 1px solid #000; padding: 2px; text-align: center; font-weight: bold; width: 3%;">เคยมาแล้ว</th>';
                tableHTML += '<th style="border: 1px solid #000; padding: 2px; text-align: center; font-weight: bold; width: 14%;">ชื่อผู้จอง</th>';
                tableHTML += '<th style="border: 1px solid #000; padding: 2px; text-align: center; font-weight: bold; width: 10%;">รายชื่อห้องพัก</th>';
                tableHTML += '<th style="border: 1px solid #000; padding: 2px; text-align: center; font-weight: bold; width: 3%;">จำนวนคืน</th>';
                tableHTML += '<th style="border: 1px solid #000; padding: 2px; text-align: center; font-weight: bold; width: 24%;">รายการของเช่า</th>';
                tableHTML += '<th style="border: 1px solid #000; padding: 2px; text-align: center; font-weight: bold; width: 4%;">ราคาทั้งหมด</th>';
                tableHTML += '<th style="border: 1px solid #000; padding: 2px; text-align: center; font-weight: bold; width: 4%;">เงินมัดจำ</th>';
                tableHTML += '<th style="border: 1px solid #000; padding: 2px; text-align: center; font-weight: bold; width: 4%;">ส่วนที่เหลือ</th>';
                tableHTML += '<th style="border: 1px solid #000; padding: 2px; text-align: center; font-weight: bold; width: 10%;">หมายเหตุ</th>';
                tableHTML += '<th style="border: 1px solid #000; padding: 2px; text-align: center; font-weight: bold; width: 12%;">&nbsp;</th>';
                tableHTML += '<th style="border: 1px solid #000; padding: 2px; text-align: center; font-weight: bold; width: 12%;">&nbsp;</th>';

                tableHTML += '</tr></thead>';
            }

            tableHTML += '<tbody>';
            var rows = document.querySelectorAll('.mydatagrid .rows');

            for (var i = 0; i < rows.length; i++) {
                // ลดความสูงลงอีก 30% จาก 105px เหลือ 74px
                tableHTML += '<tr style="height: 74px;">';

                var cells = rows[i].querySelectorAll('td');
                var data = {
                    countReserved: '',
                    name: '',
                    accomName: '',
                    stayDays: '',
                    items: '',
                    totalPrice: '',
                    deposit: '',
                    remain: '',
                    remark: ''
                };

                // ดึงข้อมูลจากแต่ละเซลล์
                for (var j = 0; j < cells.length; j++) {
                    if (!cells[j].classList.contains('hidden')) {

                        // ดึงข้อมูล "เคยมาแล้ว" จาก data attribute
                        if (j === 0) { // คอลัมน์แรกคือ "เคยมาแล้ว"
                            var spanElement = cells[j].querySelector('.print-only');
                            if (spanElement) {
                                // ลองดึงจาก data attribute ก่อน
                                var countData = spanElement.getAttribute('data-count');
                                if (countData) {
                                    data.countReserved = countData + ' ครั้ง';
                                } else {
                                    // ถ้าไม่มี data attribute ให้ดึงจาก text content
                                    var spanText = spanElement.textContent || spanElement.innerText;
                                    if (spanText && spanText.trim() !== '') {
                                        data.countReserved = spanText;
                                    } else {
                                        // ถ้ายังไม่มี ให้ลองดึงจากปุ่ม
                                        var button = cells[j].querySelector('.btn');
                                        if (button) {
                                            data.countReserved = button.textContent || button.innerText;
                                        }
                                    }
                                }
                            }
                        }

                        // ดึงข้อมูลจาก header text สำหรับคอลัมน์อื่นๆ
                        var headerText = '';
                        if (headerRow && headerRow.querySelectorAll('th')[j]) {
                            headerText = headerRow.querySelectorAll('th')[j].innerText;
                        }

                        var cellContent = cells[j].textContent || cells[j].innerText;

                        if (headerText === 'ชื่อผู้จอง') data.name = cellContent;
                        else if (headerText === 'รายชื่อห้องพัก') data.accomName = cellContent;
                        else if (headerText === 'จำนวนคืน') data.stayDays = cellContent;
                        else if (headerText === 'รายการของเช่า') data.items = cellContent;
                        else if (headerText === 'ราคาทั้งหมด') data.totalPrice = cellContent;
                        else if (headerText === 'ยอดเงินรับมา') data.deposit = cellContent;
                        else if (headerText === 'ส่วนที่เหลือ') data.remain = cellContent;
                        else if (headerText === 'หมายเหตุ') data.remark = cellContent;
                    }
                }

                // สร้างแถวข้อมูลด้วยความกว้างใหม่ และความสูง 74px (ลดลงอีก 30% จาก 105px)
                tableHTML += '<td style="border: 1px solid #000; padding: 2px; text-align: center; width: 3%; height: 74px; vertical-align: top;">' + (data.countReserved || '&nbsp;') + '</td>';
                tableHTML += '<td style="border: 1px solid #000; padding: 2px; text-align: left; width: 14%; height: 74px; vertical-align: top;">' + (data.name || '&nbsp;') + '</td>';
                tableHTML += '<td style="border: 1px solid #000; padding: 2px; text-align: left; width: 10%; height: 74px; vertical-align: top;">' + (data.accomName || '&nbsp;') + '</td>';
                tableHTML += '<td style="border: 1px solid #000; padding: 2px; text-align: center; width: 3%; height: 74px; vertical-align: top;">' + (data.stayDays || '&nbsp;') + '</td>';
                tableHTML += '<td style="border: 1px solid #000; padding: 2px; text-align: left; width: 24%; height: 74px; vertical-align: top;">' + (data.items || '&nbsp;') + '</td>';
                tableHTML += '<td style="border: 1px solid #000; padding: 2px; text-align: center; width: 4%; height: 74px; vertical-align: top;">' + (data.totalPrice || '&nbsp;') + '</td>';
                tableHTML += '<td style="border: 1px solid #000; padding: 2px; text-align: center; width: 4%; height: 74px; vertical-align: top;">' + (data.deposit || '&nbsp;') + '</td>';
                tableHTML += '<td style="border: 1px solid #000; padding: 2px; text-align: center; width: 4%; height: 74px; vertical-align: top;">' + (data.remain || '&nbsp;') + '</td>';
                tableHTML += '<td style="border: 1px solid #000; padding: 2px; text-align: left; width: 10%; height: 74px; vertical-align: top;">' + (data.remark || '&nbsp;') + '</td>';
                tableHTML += '<td style="border: 1px solid #000; padding: 2px; text-align: center; width: 12%; height: 74px; background-color: #f9f9f9; vertical-align: top;">&nbsp;</td>';
                tableHTML += '<td style="border: 1px solid #000; padding: 2px; text-align: center; width: 12%; height: 74px; background-color: #f9f9f9; vertical-align: top;">&nbsp;</td>';

                tableHTML += '</tr>';
            }
            tableHTML += '</tbody></table>';

            // เพิ่มตารางแนวนอนสำหรับกรอกค่าก่อน Footer
            var summaryTableHTML = `
                <div style="margin-top: 20px;">
                    <table style="width: 100%; border-collapse: collapse; font-size: 11px; border: 1px solid #000; margin-bottom: 10px;">
                        <tr>
                            <td style="border: 1px solid #000; padding: 1px; text-align: left; width: 33.33%; vertical-align: top;">
                                <strong>ยอดเงินที่โอนเข้าบัญชีบริษัท:</strong><br>
                                <div style="height: 10px; border-bottom: 1px dashed #ccc; margin-top: 1px;">&nbsp;</div>
                            </td>
                            <td style="border: 1px solid #000; padding: 1px; text-align: left; width: 33.33%; vertical-align: top;">
                                <strong>ยอดเงินที่โอนเข้าบัญชีเงินสด:</strong><br>
                                <div style="height: 10px; border-bottom: 1px dashed #ccc; margin-top: 1px;">&nbsp;</div>
                            </td>
                            <td style="border: 1px solid #000; padding: 1px; text-align: left; width: 33.33%; vertical-align: top;">
                                <strong>เงินสด:</strong><br>
                                <div style="height: 10px; border-bottom: 1px dashed #ccc; margin-top: 1px;">&nbsp;</div>
                            </td>
                        </tr>
                    </table>
                </div>
            `;

            // Get date label text safely
            var dateLabel = document.getElementById('<%= Label1.ClientID %>');
            var dateLabelText = dateLabel ? dateLabel.innerText : '';

            printWindow.document.write(`
                <html>
                    <head>
                        <title>รายการผู้เข้าพักรายวัน - ${dateLabelText}</title>
                        <style>
                            @page {
                                margin: 0.2cm;
                                size: landscape;
                            }
                            body { 
                                font-family: 'Tahoma', 'Sans-serif'; 
                                margin: 0;
                                padding: 0;
                                font-size: 10px;
                            }
                            h2, h3 { 
                                text-align: center; 
                                margin: 5px 0;
                                padding: 0;
                                line-height: 1.2;
                            }
                            h2 {
                                font-size: 14px;
                                margin-bottom: 2px;
                            }
                            h3 {
                                font-size: 12px;
                                margin-bottom: 5px;
                            }
                            table { 
                                width: 100%; 
                                border-collapse: collapse; 
                                font-size: 9px;
                                margin: 0;
                                padding: 0;
                                table-layout: fixed;
                            }
                            th, td {
                                border: 1px solid #000;
                                padding: 2px;
                                text-align: center;
                                word-wrap: break-word;
                                overflow: hidden;
                            }
                            th {
                                background-color: #f2f2f2;
                                font-weight: bold;
                                height: 25px;
                            }
                            td {
                                height: 74px;
                                vertical-align: top;
                            }
                            .summary-table {
                                width: 100%;
                                border-collapse: collapse;
                                font-size: 11px;
                                margin-top: 20px;
                                margin-bottom: 10px;
                            }
                            .summary-table td {
                                vertical-align: top;
                                text-align: left;
                                padding: 1px;
                                border: 1px solid #000;
                            }
                            .dashed-line {
                                height: 10px;
                                border-bottom: 1px dashed #666;
                                margin-top: 1px;
                            }
                            .print-footer { 
                                margin-top: 10px; 
                                text-align: right; 
                                font-size: 9px;
                                padding: 0;
                            }
                            @media print {
                                body { 
                                    margin: 0.2cm;
                                    padding: 0;
                                }
                                table { 
                                    width: 100%; 
                                    page-break-inside: auto;
                                }
                                tr { 
                                    page-break-inside: avoid; 
                                    page-break-after: auto; 
                                }
                                * {
                                    -webkit-print-color-adjust: exact;
                                    color-adjust: exact;
                                }
                            }
                        </style>
                    </head>
                    <body>
                        <h2>รายการผู้เข้าพักรายวัน</h2>
                        <h3>${dateLabelText}</h3>
                        ${tableHTML}
                        ${summaryTableHTML}
                        <div class="print-footer">
                            พิมพ์เมื่อ: ${new Date().toLocaleDateString('th-TH')} ${new Date().toLocaleTimeString('th-TH', { hour: '2-digit', minute: '2-digit' })}
                        </div>
                    </body>
                </html>
            `);

            printWindow.document.close();
            printWindow.focus();

            setTimeout(function () {
                printWindow.print();
                printWindow.close();
            }, 500);
        }
    </script>
</asp:Content>