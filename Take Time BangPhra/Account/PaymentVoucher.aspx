<%@ Page MaintainScrollPositionOnPostback="true" Title="" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="PaymentVoucher.aspx.cs" Inherits="Take_Time_BangPhra.Account.Report.PaymentVoucher" %>
<%@ Register assembly="Microsoft.ReportViewer.WebForms" namespace="Microsoft.Reporting.WebForms" tagprefix="rsweb" %>
<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">
     <link rel="stylesheet" href="/Content/jquery-ui.css">
  <link rel="stylesheet" href="/Content/style.css">
    <link rel="stylesheet" type="text/css" href="/Content/GridView.css">
     <style>


 .header-center{
        text-align:center;
    }
  .header-right{
        text-align:right;
    }
  .autocomplete {
  position: relative;
  display: inline-block;
}

     .autocomplete-items {
  position: absolute;
  border: 1px solid #d4d4d4;
  border-bottom: none;
  border-top: none;
  z-index: 99;
  /*position the autocomplete items to be the same width as the container:*/
  top: 100%;
  left: 0;
  right: 0;
  background-color: lemonchiffon;
}
.autocomplete-items div {
  padding: 10px;
  cursor: pointer;
  border-bottom: 1px solid #d4d4d4;
}

.autocomplete-active {
  /*when navigating through the items using the arrow keys:*/
  background-color: DodgerBlue !important;
  color: #ffffff;
}
         </style>
            <style>
            th, td {
  padding: 5px;
}
                .auto-style1 {
                    width: 20%;
                }
                </style>
      <script type="text/javascript">
      function checkEnter(event) {
          if (event.key === 'Enter') {
              __doPostBack('<%= TextBox9.UniqueID %>', '');
              event.preventDefault();
          }
      }
      </script>
    
    <p>
        &nbsp;</p>
    <p class="text-center">
        <strong>สร้างใบสำคัญจ่าย</strong><div class="text-center">
            <br />
        </div>
        <table style="width:100%;">
             <tr>
                 <td class="modal-sm" style="width: 20%; text-align: right">วันที่ใบสำคัญจ่าย:</td>
                <td>
                    &nbsp;<asp:TextBox ID="TextBox8" runat="server" Width="30%" TextMode="Date"></asp:TextBox>
                 </td>
            </tr>
            <tr style="background-color:whitesmoke;">
                <td class="auto-style1" style="text-align: right" rowspan="2">จ่ายเงินให้: </td>
                <td>
                     <div class="autocomplete" style="width:100%">
                    <asp:TextBox ID="TextBox9" runat="server" Width="60%" autocomplete="off" AutoPostBack="True" OnTextChanged="TextBox9_TextChanged"></asp:TextBox>
                    <asp:Literal ID="Literal1" runat="server"></asp:Literal>
                         </div>
                </td>
              
            </tr>
            <tr style="background-color:whitesmoke;">
                <td>
                    <asp:DropDownList ID="DropDownList5" runat="server" Width="60%" AppendDataBoundItems="true" AutoPostBack="True" OnSelectedIndexChanged="DropDownList5_SelectedIndexChanged">
                        <asp:ListItem Value="%">---โปรดเลือก---</asp:ListItem>
                    </asp:DropDownList>
                    <asp:SqlDataSource ID="SqlDataSource5" runat="server" ConnectionString="<%$ ConnectionStrings:TaketimeConnectionString %>" SelectCommand="Select distinct(Vendor_Group) from Vendor"></asp:SqlDataSource>
                    <br />
                    <asp:DropDownList ID="DropDownList1" runat="server" Width="60%" AppendDataBoundItems="true">
                        <asp:ListItem>---โปรดเลือก---</asp:ListItem>
                    </asp:DropDownList>
                    <asp:SqlDataSource ID="SqlDataSource1" runat="server" ConnectionString="<%$ ConnectionStrings:TaketimeConnectionString %>" SelectCommand="SELECT * FROM [Vendor] WHERE ([Status] = 'True') order by Vendor_Group,Name ASC">
                        <SelectParameters>
                            <asp:Parameter DefaultValue="True" Name="Status" Type="Boolean" />
                        </SelectParameters>
                    </asp:SqlDataSource>
                    <asp:Button ID="Button5" runat="server" Text="สร้าง/แก้ไข Vendor" Width="30%" OnClick="Button5_Click" />
                </td>
              
            </tr>
            <tr>
                 <td class="modal-sm" style="width: 20%; text-align: right">วิธีจ่ายเงิน:</td>
                <td>&nbsp;<asp:DropDownList ID="DropDownList2" runat="server" Width="60%" AppendDataBoundItems="true">
                <asp:ListItem>---โปรดเลือก---</asp:ListItem>    
                </asp:DropDownList>
                    <asp:SqlDataSource ID="SqlDataSource2" runat="server" ConnectionString="<%$ ConnectionStrings:TaketimeConnectionString %>" SelectCommand="SELECT * FROM [Account_Paid_How] WHERE ([Status] = 'True')">
                        <SelectParameters>
                            <asp:Parameter DefaultValue="True" Name="Status" Type="Boolean" />
                        </SelectParameters>
                    </asp:SqlDataSource>
                 </td>
            
            </tr>

            <tr style="background-color:whitesmoke;">
                 <td class="modal-sm" style="width: 20%; text-align: right">ประเภทการจ่ายเงิน:</td>
                <td>&nbsp;<asp:DropDownList ID="DropDownList3" runat="server" Width="60%" AppendDataBoundItems="true">
                <asp:ListItem>---โปรดเลือก---</asp:ListItem>    
                </asp:DropDownList>
                    <asp:SqlDataSource ID="SqlDataSource3" runat="server" ConnectionString="<%$ ConnectionStrings:TaketimeConnectionString %>" SelectCommand="SELECT * FROM [Account_Paid_Type] WHERE ([Status] = 'True')">
                        <SelectParameters>
                            <asp:Parameter DefaultValue="True" Name="Status" Type="Boolean" />
                        </SelectParameters>
                    </asp:SqlDataSource>
                 </td>
            
            </tr>

            <tr>
                 <td class="modal-sm" style="width: 20%; text-align: right">ประเภทภาษี: </td>
                <td>
                    &nbsp;<asp:DropDownList ID="DropDownList4" runat="server" Width="60%"  OnSelectedIndexChanged="DropDownList4_SelectedIndexChanged" AppendDataBoundItems="true">
                    <asp:ListItem>---โปรดเลือก---</asp:ListItem>
                    </asp:DropDownList>
                    <asp:SqlDataSource ID="SqlDataSource4" runat="server" ConnectionString="<%$ ConnectionStrings:TaketimeConnectionString %>" SelectCommand="SELECT * FROM [Account_Vat_Type] WHERE ([Status] = 'True')">
                        <SelectParameters>
                            <asp:Parameter DefaultValue="True" Name="Status" Type="Boolean" />
                        </SelectParameters>
                    </asp:SqlDataSource>
                 </td>
            
            </tr>

           

            <tr style="background-color:whitesmoke;">
                 <td class="modal-sm" style="width: 20%; text-align: right">รายละเอียดค่าใช้จ่าย: </td>
                <td>
                    &nbsp;<asp:TextBox ID="TextBox1" runat="server" Width="60%"></asp:TextBox>
                 </td>
            
            </tr>

            <tr>
                 <td class="modal-sm" style="width: 20%; text-align: right">จำนวนเงิน(ไม่รวมภาษี): </td>
                <td>
                    &nbsp;<asp:TextBox ID="TextBox2" runat="server" Width="30%"></asp:TextBox>
                 &nbsp;บาท</td>
            
            </tr>

            <tr style="background-color:whitesmoke;">
                 <td class="modal-sm" style="width: 20%; text-align: right">&nbsp;</td>
                <td>
                    &nbsp;<asp:Button ID="Button2" runat="server" Text="เพิ่ม" Width="75px" OnClick="Button2_Click" />
                 </td>
            
            </tr>

            <tr>
                <td class="modal-sm" style="width: 20%; text-align: right">&nbsp;</td>
                 <td style="text-align: right">
                     <asp:GridView ID="GridView1" runat="server" AutoGenerateColumns="False" OnRowDeleting="GridView1_RowDeleting">
                         <Columns>
                             <asp:BoundField DataField="Number" HeaderText="ลำดับ" />
                             <asp:BoundField DataField="Detail" HeaderText="รายละเอียด" />
                             <asp:BoundField DataField="Amount" HeaderText="จำนวนเงิน" />
                             <asp:CommandField ShowDeleteButton="True" ButtonType="Button" />
                         </Columns>
                     </asp:GridView>
                     </td>
            
            </tr>

            <tr style="background-color:whitesmoke;">
                 <td class="modal-sm" style="width: 20%; text-align: right">จำนวนรวมก่อนภาษีมุลค่าเพิ่ม: </td>
                <td>
                    &nbsp;<asp:TextBox ID="TextBox3" runat="server" Width="30%" Enabled="False"></asp:TextBox>
                 &nbsp;บาท</td>
            </tr>
            <tr>
                 <td class="modal-sm" style="width: 20%; text-align: right">
                     <asp:Label ID="Label1" runat="server" Text=""></asp:Label>: </td>
                <td>
                    &nbsp;<asp:TextBox ID="TextBox4" runat="server" Width="30%" Enabled="False"></asp:TextBox>
                    &nbsp;บาท
                    <asp:CheckBox ID="CheckBox1" runat="server" Text="Edit" OnCheckedChanged="CheckBox1_CheckedChanged" />
                 </td>
            </tr>

            <tr style="background-color:whitesmoke;">
                 <td class="modal-sm" style="width: 20%; text-align: right">จำนวนสุทธิ: </td>
                <td>
                    &nbsp;<asp:TextBox ID="TextBox6" runat="server" Width="30%" Enabled="False"></asp:TextBox>
                    &nbsp;บาท</td>
            </tr>

            <tr>
                 <td class="modal-sm" style="width: 20%; text-align: right">อัพโหลดไฟล์ที่เกี่ยวข้อง: </td>
                <td>
                    <asp:FileUpload ID="FileUpload1" runat="server" Width="30%" />
                    <asp:TextBox ID="TextBox7" runat="server" Text="" Width="30%" placeholder="คำอธิบายไฟล์"></asp:TextBox>
                    &nbsp;<asp:Button ID="Button4" runat="server" Text="Upload" OnClick="Button4_Click" />
&nbsp; </td>
            </tr>

            <tr style="background-color:whitesmoke;">
                 <td class="modal-sm" style="width: 20%; text-align: right">&nbsp;</td>
                <td>
                    <asp:GridView ID="GridView2" runat="server" AutoGenerateColumns="False" OnRowDeleted="GridView2_RowDeleted" OnRowDeleting="GridView2_RowDeleting">
                        <Columns>
                            <asp:BoundField DataField="Name" HeaderText="ชื่อไฟล์" />
                            <asp:CommandField ShowDeleteButton="True" />
                        </Columns>
                    </asp:GridView>
                 </td>
            </tr>

            <tr>
                 <td class="modal-sm" style="width: 20%; text-align: right">&nbsp;</td>
                <td>
                    &nbsp;<asp:Button ID="Button3" runat="server" Text="บันทึก" Width="100px" Height="33px" OnClick="Button3_Click" />
                 </td>
            </tr>

        </table>
    </p>
    <rsweb:reportviewer Visible="false" ID="ReportViewer2" runat="server" BackColor="" ClientIDMode="AutoID" HighlightBackgroundColor="" InternalBorderColor="204, 204, 204" InternalBorderStyle="Solid" InternalBorderWidth="1px" LinkActiveColor="" LinkActiveHoverColor="" LinkDisabledColor="" PrimaryButtonBackgroundColor="" PrimaryButtonForegroundColor="" PrimaryButtonHoverBackgroundColor="" PrimaryButtonHoverForegroundColor="" SecondaryButtonBackgroundColor="" SecondaryButtonForegroundColor="" SecondaryButtonHoverBackgroundColor="" SecondaryButtonHoverForegroundColor="" SplitterBackColor="" ToolbarDividerColor="" ToolbarForegroundColor="" ToolbarForegroundDisabledColor="" ToolbarHoverBackgroundColor="" ToolbarHoverForegroundColor="" ToolBarItemBorderColor="" ToolBarItemBorderStyle="Solid" ToolBarItemBorderWidth="1px" ToolBarItemHoverBackColor="" ToolBarItemPressedBorderColor="51, 102, 153" ToolBarItemPressedBorderStyle="Solid" ToolBarItemPressedBorderWidth="1px" ToolBarItemPressedHoverBackColor="153, 187, 226" Height="500px" CssClass="auto-style5" style="margin-top: 172px">
        <LocalReport EnableExternalImages="true" ReportPath="Account\Report\Payment.rdlc">
            
        </LocalReport>
</rsweb:reportviewer>
</asp:Content>
