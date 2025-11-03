<%@ Page Title="ตรวจสอบเอกสารบัญชี" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="CheckDocument.aspx.cs" Inherits="Take_Time_BangPhra.Account.CheckDocument" MaintainScrollPositionOnPostback="true" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">

    <style>
        .check-document-container {
            padding: 20px;
        }

        .page-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 30px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
        }

        .page-header h1 {
            margin: 0;
            font-size: 28px;
            font-weight: 700;
        }

        .page-header p {
            margin: 5px 0 0;
            opacity: 0.9;
        }

        .filter-section {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.08);
            margin-bottom: 25px;
        }

        .filter-section h3 {
            color: #333;
            margin-top: 0;
            margin-bottom: 20px;
            font-size: 20px;
            border-bottom: 2px solid #667eea;
            padding-bottom: 10px;
        }

        .filter-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }

        .filter-group {
            display: flex;
            flex-direction: column;
        }

        .filter-group label {
            font-weight: 600;
            color: #555;
            margin-bottom: 8px;
            font-size: 14px;
        }

        .filter-group input[type="date"],
        .filter-group select {
            padding: 10px 15px;
            border: 2px solid #e0e0e0;
            border-radius: 6px;
            font-size: 14px;
            transition: border-color 0.3s;
        }

        .filter-group input:focus,
        .filter-group select:focus {
            border-color: #667eea;
            outline: none;
        }

        .filter-actions {
            display: flex;
            gap: 10px;
            margin-top: 20px;
            flex-wrap: wrap;
        }

        .btn {
            padding: 12px 30px;
            border: none;
            border-radius: 6px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s;
            font-size: 14px;
        }

        .btn-primary {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }

        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
        }

        .btn-success {
            background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%);
            color: white;
        }

        .btn-success:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(17, 153, 142, 0.4);
        }

        .btn-info {
            background: linear-gradient(135deg, #209cee 0%, #3273dc 100%);
            color: white;
        }

        .summary-cards {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 25px;
        }

        .summary-card {
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.08);
            text-align: center;
            transition: transform 0.3s;
        }

        .summary-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 4px 20px rgba(0,0,0,0.15);
        }

        .summary-card .icon {
            font-size: 36px;
            margin-bottom: 10px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }

        .summary-card .label {
            color: #666;
            font-size: 14px;
            margin-bottom: 8px;
        }

        .summary-card .value {
            color: #333;
            font-size: 28px;
            font-weight: 700;
        }

        .summary-card.cash {
            border-top: 4px solid #4caf50;
        }

        .summary-card.transfer {
            border-top: 4px solid #2196f3;
        }

        .summary-card.credit {
            border-top: 4px solid #ff9800;
        }

        .summary-card.total {
            border-top: 4px solid #9c27b0;
        }

        .chart-section {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
            gap: 20px;
            margin-bottom: 25px;
        }

        .chart-card {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.08);
        }

        .chart-card h3 {
            color: #333;
            margin-top: 0;
            margin-bottom: 20px;
            font-size: 18px;
        }

        .category-breakdown,
        .payment-breakdown {
            margin-top: 15px;
        }

        .breakdown-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 12px;
            border-bottom: 1px solid #f0f0f0;
        }

        .breakdown-item:last-child {
            border-bottom: none;
        }

        .breakdown-label {
            display: flex;
            align-items: center;
            gap: 10px;
            font-weight: 500;
            color: #555;
        }

        .breakdown-label i {
            font-size: 20px;
        }

        .breakdown-value {
            font-weight: 700;
            color: #333;
            font-size: 16px;
        }

        .data-table {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.08);
            overflow-x: auto;
        }

        .data-table h3 {
            color: #333;
            margin-top: 0;
            margin-bottom: 20px;
            font-size: 18px;
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .data-table table {
            width: 100%;
            border-collapse: collapse;
            font-size: 14px;
        }

        .data-table th {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 12px;
            text-align: left;
            font-weight: 600;
            white-space: nowrap;
        }

        .data-table td {
            padding: 12px;
            border-bottom: 1px solid #e0e0e0;
        }

        .data-table tr:hover {
            background-color: #f8f9fa;
        }

        .badge {
            padding: 5px 12px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
            white-space: nowrap;
        }

        .badge-checkin {
            background-color: #4caf50;
            color: white;
        }

        .badge-sale {
            background-color: #2196f3;
            color: white;
        }

        .badge-rental {
            background-color: #ff9800;
            color: white;
        }

        .badge-booking {
            background-color: #9c27b0;
            color: white;
        }

        .alert {
            padding: 15px 20px;
            border-radius: 6px;
            margin-bottom: 20px;
            font-weight: 500;
        }

        .alert-info {
            background-color: #d1ecf1;
            border: 1px solid #bee5eb;
            color: #0c5460;
        }

        .tabs {
            display: flex;
            gap: 10px;
            margin-bottom: 20px;
            border-bottom: 2px solid #e0e0e0;
            flex-wrap: wrap;
        }

        .tab {
            padding: 12px 24px;
            cursor: pointer;
            border: none;
            background: transparent;
            color: #666;
            font-weight: 600;
            border-bottom: 3px solid transparent;
            transition: all 0.3s;
        }

        .tab:hover {
            color: #667eea;
        }

        .tab.active {
            color: #667eea;
            border-bottom-color: #667eea;
        }

        .tab-content {
            display: none;
        }

        .tab-content.active {
            display: block;
        }

        .export-section {
            text-align: right;
            margin-bottom: 15px;
        }

        /* Responsive */
        @media (max-width: 768px) {
            .filter-grid {
                grid-template-columns: 1fr;
            }

            .summary-cards {
                grid-template-columns: repeat(2, 1fr);
            }

            .chart-section {
                grid-template-columns: 1fr;
            }

            .filter-actions {
                flex-direction: column;
            }

            .btn {
                width: 100%;
            }
        }

        /* GridView Custom Styling */
        .GridView {
            width: 100%;
            border-collapse: collapse;
        }

        .GridView th {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 12px;
            text-align: left;
            font-weight: 600;
        }

        .GridView td {
            padding: 12px;
            border-bottom: 1px solid #e0e0e0;
        }

        .GridView tr:hover {
            background-color: #f8f9fa;
        }

        .no-data {
            text-align: center;
            padding: 40px;
            color: #999;
            font-size: 16px;
        }
    </style>

    <div class="check-document-container">
        <!-- Page Header -->
        <div class="page-header">
            <h1><i class="fas fa-file-invoice-dollar"></i> ตรวจสอบเอกสารบัญชี</h1>
            <p>สรุปรายรับ-รายจ่ายรายวันของทีม Front Office</p>
        </div>

        <!-- Alert Message -->
        <asp:Panel ID="pnlAlert" runat="server" CssClass="alert alert-info" Visible="false">
            <i class="fas fa-info-circle"></i>
            <asp:Label ID="lblAlert" runat="server"></asp:Label>
        </asp:Panel>

        <!-- Filter Section -->
        <div class="filter-section">
            <h3><i class="fas fa-filter"></i> กรองข้อมูล</h3>
            <div class="filter-grid">
                <div class="filter-group">
                    <label>วันที่เริ่มต้น</label>
                    <asp:TextBox ID="txtStartDate" runat="server" TextMode="Date"></asp:TextBox>
                </div>
                <div class="filter-group">
                    <label>วันที่สิ้นสุด</label>
                    <asp:TextBox ID="txtEndDate" runat="server" TextMode="Date"></asp:TextBox>
                </div>
                <div class="filter-group">
                    <label>ช่องทางชำระเงิน</label>
                    <asp:DropDownList ID="ddlPaymentChannel" runat="server">
                        <asp:ListItem Value="" Selected="True">ทั้งหมด</asp:ListItem>
                    </asp:DropDownList>
                </div>
                <div class="filter-group">
                    <label>หมวดหมู่รายได้</label>
                    <asp:DropDownList ID="ddlRevenueCategory" runat="server">
                        <asp:ListItem Value="" Selected="True">ทั้งหมด</asp:ListItem>
                        <asp:ListItem Value="ACCOMMODATION">ที่พัก</asp:ListItem>
                        <asp:ListItem Value="FOOD_BEVERAGE">อาหาร-เครื่องดื่ม</asp:ListItem>
                        <asp:ListItem Value="RENTAL">เช่าอุปกรณ์</asp:ListItem>
                        <asp:ListItem Value="OTHER">อื่นๆ</asp:ListItem>
                    </asp:DropDownList>
                </div>
            </div>
            <div class="filter-actions">
                <asp:Button ID="btnSearch" runat="server" Text="ค้นหา" CssClass="btn btn-primary" OnClick="btnSearch_Click" />
                <asp:Button ID="btnToday" runat="server" Text="วันนี้" CssClass="btn btn-info" OnClick="btnToday_Click" CausesValidation="false" />
                <asp:Button ID="btnThisMonth" runat="server" Text="เดือนนี้" CssClass="btn btn-info" OnClick="btnThisMonth_Click" CausesValidation="false" />
                <asp:Button ID="btnExport" runat="server" Text="Export Excel" CssClass="btn btn-success" OnClick="btnExport_Click" CausesValidation="false" />
            </div>
        </div>

        <!-- Summary Cards -->
        <div class="summary-cards">
            <div class="summary-card cash">
                <div class="icon"><i class="fas fa-money-bill-wave"></i></div>
                <div class="label">เงินสด</div>
                <div class="value">
                    <asp:Label ID="lblCashTotal" runat="server" Text="0.00"></asp:Label>
                </div>
            </div>
            <div class="summary-card transfer">
                <div class="icon"><i class="fas fa-university"></i></div>
                <div class="label">โอนเงิน</div>
                <div class="value">
                    <asp:Label ID="lblTransferTotal" runat="server" Text="0.00"></asp:Label>
                </div>
            </div>
            <div class="summary-card credit">
                <div class="icon"><i class="fas fa-credit-card"></i></div>
                <div class="label">บัตรเครดิต</div>
                <div class="value">
                    <asp:Label ID="lblCreditTotal" runat="server" Text="0.00"></asp:Label>
                </div>
            </div>
            <div class="summary-card total">
                <div class="icon"><i class="fas fa-calculator"></i></div>
                <div class="label">ยอดรวมทั้งหมด</div>
                <div class="value">
                    <asp:Label ID="lblGrandTotal" runat="server" Text="0.00"></asp:Label>
                </div>
            </div>
        </div>

        <!-- Charts Section -->
        <div class="chart-section">
            <!-- Revenue by Category -->
            <div class="chart-card">
                <h3><i class="fas fa-chart-pie"></i> รายได้ตามหมวดหมู่</h3>
                <div class="category-breakdown">
                    <asp:Repeater ID="rptCategoryBreakdown" runat="server">
                        <ItemTemplate>
                            <div class="breakdown-item">
                                <div class="breakdown-label">
                                    <i class='<%# GetCategoryIcon(Eval("Category").ToString()) %>'></i>
                                    <%# GetCategoryDisplayName(Eval("Category").ToString()) %>
                                </div>
                                <div class="breakdown-value">
                                    ฿<%# String.Format("{0:N2}", Eval("Revenue")) %>
                                </div>
                            </div>
                        </ItemTemplate>
                    </asp:Repeater>
                </div>
            </div>

            <!-- Revenue by Payment Channel -->
            <div class="chart-card">
                <h3><i class="fas fa-chart-bar"></i> รายได้ตามช่องทางชำระเงิน</h3>
                <div class="payment-breakdown">
                    <asp:Repeater ID="rptPaymentBreakdown" runat="server">
                        <ItemTemplate>
                            <div class="breakdown-item">
                                <div class="breakdown-label">
                                    <i class='<%# GetPaymentIcon(Eval("Channel").ToString()) %>'></i>
                                    <%# Eval("Channel") %>
                                </div>
                                <div class="breakdown-value">
                                    ฿<%# String.Format("{0:N2}", Eval("Revenue")) %>
                                </div>
                            </div>
                        </ItemTemplate>
                    </asp:Repeater>
                </div>
            </div>
        </div>

        <!-- Tabs for different views -->
        <div class="tabs">
            <button class="tab active" onclick="showTab(event, 'tab-transactions')">
                <i class="fas fa-list"></i> รายการธุรกรรม
            </button>
            <button class="tab" onclick="showTab(event, 'tab-summary')">
                <i class="fas fa-table"></i> สรุปยอด
            </button>
        </div>

        <!-- Tab Content: Transactions -->
        <div id="tab-transactions" class="tab-content active">
            <div class="data-table">
                <div class="export-section">
                    <asp:Label ID="lblTransactionCount" runat="server" Text="ทั้งหมด 0 รายการ" Font-Bold="true"></asp:Label>
                </div>
                <h3><i class="fas fa-receipt"></i> รายการธุรกรรมทั้งหมด</h3>
                <asp:GridView ID="gvTransactions" runat="server"
                    AutoGenerateColumns="False"
                    CssClass="GridView"
                    AllowPaging="True"
                    PageSize="50"
                    OnPageIndexChanging="gvTransactions_PageIndexChanging"
                    EmptyDataText="ไม่พบข้อมูลธุรกรรม">
                    <Columns>
                        <asp:BoundField DataField="TransactionDate" HeaderText="วันที่" DataFormatString="{0:dd/MM/yyyy}" />
                        <asp:BoundField DataField="TransactionTime" HeaderText="เวลา" DataFormatString="{0:HH:mm}" />
                        <asp:BoundField DataField="Receipt_Number" HeaderText="เลขที่เอกสาร" />
                        <asp:BoundField DataField="CustomerName" HeaderText="ลูกค้า" />
                        <asp:BoundField DataField="Category" HeaderText="หมวดหมู่" />
                        <asp:BoundField DataField="PaymentChannel" HeaderText="ช่องทางชำระ" />
                        <asp:BoundField DataField="Total_Amount" HeaderText="จำนวนเงิน" DataFormatString="{0:N2}" ItemStyle-HorizontalAlign="Right" />
                        <asp:TemplateField HeaderText="สถานะ">
                            <ItemTemplate>
                                <span class='badge <%# GetTransactionBadge(Eval("IsCheckIn")) %>'>
                                    <%# GetTransactionStatus(Eval("IsCheckIn")) %>
                                </span>
                            </ItemTemplate>
                        </asp:TemplateField>
                        <asp:BoundField DataField="CreatedBy" HeaderText="ผู้สร้าง" />
                    </Columns>
                    <PagerStyle HorizontalAlign="Center" CssClass="pager" />
                </asp:GridView>
            </div>
        </div>

        <!-- Tab Content: Summary -->
        <div id="tab-summary" class="tab-content">
            <div class="data-table">
                <h3><i class="fas fa-chart-line"></i> สรุปยอดรายวัน</h3>
                <asp:GridView ID="gvDailySummary" runat="server"
                    AutoGenerateColumns="False"
                    CssClass="GridView"
                    EmptyDataText="ไม่พบข้อมูลสรุปยอด">
                    <Columns>
                        <asp:BoundField DataField="TransactionDate" HeaderText="วันที่" DataFormatString="{0:dd/MM/yyyy}" />
                        <asp:BoundField DataField="PaymentChannel" HeaderText="ช่องทาง" />
                        <asp:BoundField DataField="CategoryName" HeaderText="หมวดหมู่" />
                        <asp:BoundField DataField="TransactionCount" HeaderText="จำนวนรายการ" ItemStyle-HorizontalAlign="Center" />
                        <asp:BoundField DataField="TotalRevenue" HeaderText="รายได้รวม" DataFormatString="{0:N2}" ItemStyle-HorizontalAlign="Right" />
                        <asp:BoundField DataField="CheckInRevenue" HeaderText="เช็คอิน" DataFormatString="{0:N2}" ItemStyle-HorizontalAlign="Right" />
                        <asp:BoundField DataField="AccommodationRevenue" HeaderText="ที่พัก" DataFormatString="{0:N2}" ItemStyle-HorizontalAlign="Right" />
                        <asp:BoundField DataField="OtherRevenue" HeaderText="อื่นๆ" DataFormatString="{0:N2}" ItemStyle-HorizontalAlign="Right" />
                    </Columns>
                </asp:GridView>
            </div>
        </div>
    </div>

    <script type="text/javascript">
        function showTab(evt, tabName) {
            // Hide all tab contents
            var tabContents = document.getElementsByClassName("tab-content");
            for (var i = 0; i < tabContents.length; i++) {
                tabContents[i].classList.remove("active");
            }

            // Remove active class from all tabs
            var tabs = document.getElementsByClassName("tab");
            for (var i = 0; i < tabs.length; i++) {
                tabs[i].classList.remove("active");
            }

            // Show selected tab content
            document.getElementById(tabName).classList.add("active");

            // Add active class to clicked tab
            evt.currentTarget.classList.add("active");
        }

        // Auto-hide alert after 5 seconds
        setTimeout(function () {
            var alert = document.getElementById('<%= pnlAlert.ClientID %>');
            if (alert) {
                alert.style.display = 'none';
            }
        }, 5000);
    </script>
</asp:Content>
