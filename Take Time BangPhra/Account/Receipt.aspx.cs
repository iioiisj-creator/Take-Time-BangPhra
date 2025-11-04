using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Data;
using System.Configuration;
using System.IO;
using Microsoft.Reporting.WebForms;
using System.Globalization;
using iTextSharp.text.pdf.qrcode;
using iTextSharp.text.pdf;
using ECertificateAPI;
using System.Net.Mail;
using Take_Time_BangPhra.Admin;
using iTextSharp.text.pdf.parser;

namespace Take_Time_BangPhra.Account.Report
{
    public partial class Receipt : System.Web.UI.Page
    {
        _Default code = new _Default();
        string conn = ConfigurationManager.ConnectionStrings["TaketimeConnectionString"].ConnectionString;
        Reservation rv = new Reservation();

        protected void Page_Load(object sender, EventArgs e)
        {
            this.MaintainScrollPositionOnPostBack = true;
            try
            {
                if (Session["permission"].ToString() == "True" && (Session["User"].ToString() == "Owner" || Session["User"].ToString() == "Admin"))
                {

                }
                else
                {
                    Response.Redirect("/Default");
                }
            }
            catch
            {
                Response.Redirect("/Default");
            }

            if (!IsPostBack)
            {
                DataTable dtCustomerType = code.DatabaseQuery(conn, "Select [Customer_Type],ID From Customer_Type");
                
                
                for (int i = 0; i < dtCustomerType.Rows.Count; i++)
                {
                    DropDownList8.Items.Add(new ListItem(dtCustomerType.Rows[i][0].ToString(), dtCustomerType.Rows[i][1].ToString()));
                }
                
                DropDownList8.DataBind();

                DataTable dtPaidHow = code.DatabaseQuery(SqlDataSource2.ConnectionString, SqlDataSource2.SelectCommand);
                for (int i = 0; i < dtPaidHow.Rows.Count; i++)
                {
                    DropDownList2.Items.Add(new ListItem(dtPaidHow.Rows[i]["Paid_How"].ToString(), dtPaidHow.Rows[i]["ID"].ToString()));
                }
                DropDownList2.DataBind();


                DataTable dtVatType = code.DatabaseQuery(SqlDataSource4.ConnectionString, SqlDataSource4.SelectCommand);
                for (int i = 0; i < dtVatType.Rows.Count; i++)
                {
                    DropDownList4.Items.Add(new ListItem(dtVatType.Rows[i]["Vat_Type"].ToString(), dtVatType.Rows[i]["ID"].ToString()));
                }
                DropDownList4.DataBind();

                getAddress("SELECT DISTINCT [Province] FROM [Address] order by Province ASC", "SELECT DISTINCT [District] FROM [Address] order by District ASC", "SELECT DISTINCT [SubDistrict] FROM [Address] order by SubDistrict ASC");

                string command = Request.QueryString["command"];
                string uid = Request.QueryString["uid"];
                
                if(command == "edit")
                {


                    DataTable dtReceipt = code.DatabaseQuery(conn, "Select * from Account_Receipt left join Reservation on Reservation.ID = Reservation_ID Where Account_Receipt.UID = '" + uid+"'");
                    string id = dtReceipt.Rows[0]["ID"].ToString();
                    DataTable dtReceiptDetail = code.DatabaseQuery(conn, "Select Number,ProductType_ID,Product_Data,Product_Amount,Product_Unit,Price_PerPeice,Price_Amount from Account_Receipt_Detail Where Receipt_ID = '" + id + "'");
                    DataTable dtcustomer = new DataTable();
                    try
                    {
                        if( Convert.ToInt32(dtReceipt.Rows[0]["Customer_ID"].ToString()) > 0)
                        {
                            dtcustomer = code.DatabaseQuery(conn, "Select * from Customer left join Customer_Type on Customer_Type_ID = Customer_Type.ID left join Address on Address.ID = Address_ID Where Customer.ID = '" + dtReceipt.Rows[0]["Customer_ID"].ToString() + "'");
                        }
                        else
                        {
                            dtcustomer = code.DatabaseQuery(conn, "Select * from Customer left join Customer_Type on Customer_Type_ID = Customer_Type.ID left join Address on Address.ID = Address_ID Where MobilePhone = '" + dtReceipt.Rows[0]["Customer_MobilePhone"].ToString() + "'");
                        }
                        
                    }
                    catch {
                        dtcustomer = code.DatabaseQuery(conn, "Select * from Customer left join Customer_Type on Customer_Type_ID = Customer_Type.ID left join Address on Address.ID = Address_ID Where MobilePhone = '" + dtReceipt.Rows[0]["Customer_MobilePhone"].ToString() + "'");
                        
                    }

                    try //Address
                    {
                        try
                        {
                            TextBox16.Text = dtcustomer.Rows[0]["PostalCode"].ToString();

                            DropDownList5.ClearSelection();
                            DropDownList5.Items.FindByText(dtcustomer.Rows[0]["Province"].ToString()).Selected = true;
                            DropDownList5.SelectedIndex = DropDownList5.Items.IndexOf(DropDownList5.Items.FindByText(dtcustomer.Rows[0]["Province"].ToString()));
                            DropDownList6.ClearSelection();
                            DropDownList6.Items.FindByText(dtcustomer.Rows[0]["District"].ToString()).Selected = true;
                            DropDownList6.SelectedIndex = DropDownList6.Items.IndexOf(DropDownList6.Items.FindByText(dtcustomer.Rows[0]["District"].ToString()));
                            DropDownList7.ClearSelection();
                            DropDownList7.Items.FindByText(dtcustomer.Rows[0]["SubDistrict"].ToString()).Selected = true;
                            DropDownList7.SelectedIndex = DropDownList7.Items.IndexOf(DropDownList7.Items.FindByText(dtcustomer.Rows[0]["SubDistrict"].ToString()));
                        }
                        catch { }

                        DropDownList8.ClearSelection();
                        DropDownList8.Items.FindByValue(dtcustomer.Rows[0]["Customer_Type_ID"].ToString()).Selected = true;
                        DropDownList8.SelectedIndex = DropDownList8.Items.IndexOf(DropDownList8.Items.FindByValue(dtcustomer.Rows[0]["Customer_Type_ID"].ToString()));
                        DropDownList8.DataBind();
                        if(DropDownList8.SelectedIndex == 0)
                        {
                            TextBox7.Visible = true;
                            TextBox7.Text = dtcustomer.Rows[0]["Branch_Number"].ToString();
                        }
                        else
                        {
                            TextBox7.Visible =false;
                        }

                            DropDownList2.SelectedIndex = DropDownList2.Items.IndexOf(DropDownList2.Items.FindByText(dtReceipt.Rows[0]["Paid_Type"].ToString()));
                        DropDownList2.DataBind();
                       
                        DropDownList4.SelectedIndex = DropDownList4.Items.IndexOf(DropDownList4.Items.FindByValue("1"));
                        DropDownList4.DataBind();
                    }
                    catch { }

                    if (dtReceipt.Rows[0]["NoNameinReceipt"].ToString().ToLower() == "true")
                    {
                        CheckBox3.Checked = true;
                        CheckBox3.DataBind();
                        TextBox10.Text = "ประสงค์ไม่รับใบกำกับภาษี";
                    }

                    GridView1.DataSource = dtReceiptDetail;
                    GridView1.DataBind();

                    TextBox5.Text = id;

                    TextBox8.Text = Convert.ToDateTime(dtReceipt.Rows[0]["Created_Date"].ToString()).ToString("yyyy-MM-dd") ;
                    TextBox9.Text = dtReceipt.Rows[0]["Reservation_ID"].ToString();

                    TextBox3.Text = dtReceipt.Rows[0]["Total_Amount_Exclude_Vat"].ToString();
                    TextBox4.Text = dtReceipt.Rows[0]["Vat"].ToString();
                    TextBox6.Text = dtReceipt.Rows[0]["Total_Amount"].ToString();

                    try
                    {

                        if (dtReceipt.Rows[0]["Etax"].ToString().ToLower() == "false")
                        {
                            CheckBox5.Checked = false;
                            CheckBox5.DataBind();
                        }
                        if (dtReceipt.Rows[0]["Etax"].ToString().ToLower() == "true")
                        {
                            CheckBox5.Checked = true;
                            CheckBox5.DataBind();
                            TextBox7.Visible = true;
                            TextBox7.Text = dtcustomer.Rows[0]["Branch_Number"].ToString();
                            
                        }
                    }
                    catch { }

                    if (CheckBox3.Checked == true)
                    {
                        //TextBox10.Text = "ประสงค์ไม่รับใบกำกับภาษี";
                        //TextBox11.Text = "";
                        //TextBox12.Text = "";
                        // TextBox13.Text = "";

                    }
                    else
                    {
                        TextBox10.Text = dtcustomer.Rows[0]["FullName"].ToString();
                        TextBox11.Text = dtcustomer.Rows[0]["Address"].ToString();
                        TextBox12.Text = dtcustomer.Rows[0]["IDNumber"].ToString();
                        TextBox13.Text = dtcustomer.Rows[0]["MobilePhone"].ToString();
                        TextBox17.Text = dtcustomer.Rows[0]["Email"].ToString();
                        TextBox18.Text = dtcustomer.Rows[0]["Address1"].ToString();
                    }
                    

                    DropDownList2.DataBind();
                    DropDownList2.SelectedIndex = DropDownList2.Items.IndexOf(DropDownList2.Items.FindByText(dtReceipt.Rows[0]["Paid_Type"].ToString()));
                    DropDownList2.DataBind();

                    DropDownList4.SelectedIndex = 1;
                    DropDownList4.DataBind();

                    if (dtReceipt.Rows[0]["IsDeposit"].ToString().ToLower() == "true")
                    {
                        CheckBox1.Checked = true;
                    }
                    Session["dtDetail"] = dtReceiptDetail;

                    Panel1.Visible = true;
                    string Year = Convert.ToDateTime(TextBox8.Text).Year.ToString();
                    string Month = Convert.ToDateTime(TextBox8.Text).Month.ToString();
                    string Day = Convert.ToDateTime(TextBox8.Text).Day.ToString();
                    string path = System.Configuration.ConfigurationSettings.AppSettings["ReceiptFolderPath"].ToString();
                    if (File.Exists(path + "\\" + Year + "\\" + Month + "\\" + dtReceipt.Rows[0]["ID"].ToString() + "_" + uid + ".pdf"))
                    {
                        myFrame.Attributes["src"] = "/Documents/Receipt/" + Year + "/" + Month + "/" + dtReceipt.Rows[0]["ID"].ToString() + "_" + uid+ ".pdf";
                    }
                    else
                    {
                        myFrame.Attributes["src"] = "/Documents/Receipt/" + Year + "/" + Month + "/" + dtReceipt.Rows[0]["ID"].ToString() + ".pdf";
                    }
                        

                }

                DataTable dtDetail = new DataTable();
                try
                {
                    dtDetail.Columns.Add("Number");
                    dtDetail.Columns.Add("ProductType_ID");
                    dtDetail.Columns.Add("Product_Data");
                    dtDetail.Columns.Add("Product_Amount");
                    dtDetail.Columns.Add("Product_Unit");
                    dtDetail.Columns.Add("Price_PerPeice");
                    dtDetail.Columns.Add("Price_Amount");

                }
                catch
                {

                }
                if (command == "edit")
                {
                    
                }
                else
                {
                    Session["dtDetail"] = dtDetail;
                    TextBox8.Text = DateTime.Now.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
                }
                
                DataTable dtUpload = new DataTable();
                try
                {
                    dtUpload.Columns.Add("Name");
                }
                catch
                {

                }
                Session["dtUpload"] = dtUpload;
            }

        }

        protected void Button2_Click(object sender, EventArgs e)
        {
            Label1.Text = DropDownList4.SelectedItem.Text;
            
            if (TextBox1.Text.Length > 1 && TextBox2.Text.Length > 0)
            {
                DataTable dtDetail = (DataTable)Session["dtDetail"];
                dtDetail.Rows.Add(dtDetail.Rows.Count+1,DropDownList3.SelectedValue,TextBox1.Text, TextBox14.Text, TextBox15.Text, rv.TwoDecimalPoints(Convert.ToDouble(TextBox2.Text)),rv.TwoDecimalPoints(Convert.ToDouble(TextBox14.Text) *Convert.ToDouble(TextBox2.Text)));
                Session["dtDetail"] = (DataTable)dtDetail;
                GridView1.DataSource = dtDetail;
                GridView1.DataBind();
                calAmount(dtDetail);
                TextBox1.Text = "";
                TextBox2.Text = "";
            }
            else
            {

            }
        }

        public void calAmount(DataTable dtDetail)
        {
            double totalAmount = 0;
            for(int i=0;i<dtDetail.Rows.Count;i++)
            {
                totalAmount += Convert.ToDouble(dtDetail.Rows[i]["Price_Amount"].ToString());
            }
            int vatPercent = Convert.ToInt32(code.DatabaseQuery(conn, "Select Vat_Percent from Account_Vat_Type Where Status = 'True' AND ID = "+DropDownList4.SelectedValue).Rows[0][0].ToString());
            double AmountExcludeVat = (totalAmount * 100) / (100 + vatPercent);
            double vat = totalAmount - AmountExcludeVat;
            TextBox3.Text = rv.TwoDecimalPoints(AmountExcludeVat).ToString();
            TextBox4.Text = rv.TwoDecimalPoints(vat).ToString();
            TextBox6.Text = rv.TwoDecimalPoints(totalAmount).ToString();

        }

        protected void GridView1_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {
            DataTable dtDetail = (DataTable)Session["dtDetail"];
            dtDetail.Rows[e.RowIndex].Delete();
            dtDetail.AcceptChanges();
            for(int i = 0;i<dtDetail.Rows.Count;i++)
            {
                dtDetail.Rows[i][0] = i + 1;
            }
            Session["dtDetail"] = (DataTable)dtDetail;
            GridView1.DataSource = dtDetail;
            GridView1.DataBind();
            calAmount(dtDetail);
        }

        protected void DropDownList4_SelectedIndexChanged(object sender, EventArgs e)
        {
            Label1.Text = DropDownList4.SelectedItem.Text;
        }

        protected void Button3_Click(object sender, EventArgs e)
        {
            if (TextBox6.Text.Length > 0 && DropDownList2.SelectedIndex > 0 && DropDownList4.SelectedIndex > 0)
            {
                string command = Request.QueryString["command"];
                string uid = Request.QueryString["uid"];
                string id = "";
                DataTable dtReceipt = new DataTable();
                string Year = Convert.ToDateTime(TextBox8.Text).Year.ToString();
                string Month = Convert.ToDateTime(TextBox8.Text).Month.ToString();
                string Day = Convert.ToDateTime(TextBox8.Text).Day.ToString();
                DataTable dtDetail = (DataTable)Session["dtDetail"];
                string docNum = "";

                docNum = code.createDocNumber(conn, "Account_Receipt", "REC", Year, Month, Day);

                if (command == "edit")
                {

                    dtReceipt = code.DatabaseQuery(conn, "Select * from Account_Receipt left join Reservation on Reservation.ID = Reservation_ID Where Account_Receipt.UID = '" + uid + "'");
                    id = dtReceipt.Rows[0]["ID"].ToString();
                    if (CheckBox2.Checked == true)
                    {
                        docNum = TextBox5.Text;
                    }
                    else
                    {
                        docNum = id;
                    }
                }
                else
                {

                }
                    string RecNumber = docNum;
                int reservation_id = 0;

                // Upsert customer data (insert or update) - ensures no duplicates and always latest data
                // ALWAYS matches by MobilePhone - ensures only 1 record per phone number
                // If customer type changes from Individual to Corporate (or vice versa), it updates the existing record
                long customerId = code.UpsertCustomer(
                    conn,
                    TextBox13.Text,  // MobilePhone
                    TextBox10.Text,  // Name
                    "",  // NickName
                    "",  // ComeFrom
                    "",  // Remark
                    TextBox10.Text,  // FullName
                    cleantext(TextBox11.Text),  // Address
                    TextBox12.Text,  // IDNumber
                    TextBox17.Text,  // Email
                    Convert.ToInt32(DropDownList8.SelectedValue),  // Customer_Type_ID
                    CheckAddressID(TextBox16.Text, DropDownList5.SelectedItem.Text, DropDownList6.SelectedItem.Text, DropDownList7.SelectedItem.Text),  // Address_ID
                    TextBox18.Text,  // Address1
                    TextBox7.Text  // Branch_Number
                );

                // Query customer data after upsert
                DataTable dtcustomer = code.DatabaseQuery(conn, "Select * from Customer left join Customer_Type on Customer_Type_ID = Customer_Type.ID left join Address on Address.ID = Address_ID Where ID = " + customerId);


                
                try
                {
                    dtReceipt = code.DatabaseQuery(conn, "SELECT * FROM [Account_Receipt] inner join Reservation on Reservation.ID = Reservation_ID Where Account_Receipt.ID = '" + RecNumber + "'");
                    if (dtReceipt.Rows.Count <= 0)
                    {
                        //reservation_id = code.DatabaseInsert(conn, "INSERT INTO [dbo].[Reservation] ([Customer_MobilePhone],[CheckinDate],[CheckoutDate],[StayDays],[Status],[TotalPrice],[Deposit],[Remark],[Reserve_By],[Created_Date],NoNameinReceipt) VALUES ('" + TextBox13.Text + "','" + Convert.ToDateTime(TextBox8.Text).ToString("yyyy-MM-dd") + "','" + Convert.ToDateTime(TextBox8.Text).AddDays(Convert.ToDouble(1)).ToString("yyyy-MM-dd") + "'," + "1" + ",N'ชำระเงินแล้ว'," + TextBox6.Text + "," + TextBox6.Text + ",N'" + TextBox6.Text + "', N'" + Session["UserName"].ToString() + "','" + DateTime.Now + "','False') SELECT SCOPE_IDENTITY(); ");
                        //dtReceipt = code.DatabaseQuery(conn, "SELECT * FROM [Account_Receipt] left join Reservation on Reservation.ID = Reservation_ID Where Account_Receipt.ID = '" + RecNumber + "'");
                    }
                    else
                    {
                        reservation_id = Convert.ToInt32(dtReceipt.Rows[0]["Reservation_ID"].ToString());
                    }
                }
                catch { dtReceipt = code.DatabaseQuery(conn, "SELECT * FROM [Account_Receipt] left join Reservation on Reservation.ID = Reservation_ID Where Account_Receipt.ID = '" + RecNumber + "'"); }

                if (command == "edit")
                {
                    code.DatabaseInsert(conn, "DELETE FROM [dbo].[Account_Receipt] WHERE ID = '" + id + "'");
                    code.DatabaseInsert(conn, "DELETE FROM [dbo].[Account_Receipt_Detail] WHERE Receipt_ID = '" + id + "'");
                }
                else { }
                if (reservation_id > 0)
                {
                    code.DatabaseInsert(conn, "INSERT INTO [dbo].[Account_Receipt] ([ID],[Reservation_ID],[Created_Date],[Total_Amount],[Vat],[Total_Amount_Exclude_Vat],[IsDeposit],[UseDeposit],[Paid_Type],[Status],[Created_By_ID],Etax,Customer_ID) VALUES ('" + docNum + "','" + reservation_id + "','" + Convert.ToDateTime(TextBox8.Text) + "'," + TextBox6.Text + "," + TextBox4.Text + "," + TextBox3.Text + ",'" + CheckBox1.Checked + "','False',N'" + DropDownList2.SelectedItem.Text + "','Normal'," + Session["UserID"].ToString() + ",'"+CheckBox5.Checked+"','"+ dtcustomer.Rows[0]["ID"].ToString() + "')");
                }
                else
                {
                    code.DatabaseInsert(conn, "INSERT INTO [dbo].[Account_Receipt] ([ID],[Reservation_ID],[Created_Date],[Total_Amount],[Vat],[Total_Amount_Exclude_Vat],[IsDeposit],[UseDeposit],[Paid_Type],[Status],[Created_By_ID],Etax,Customer_ID) VALUES ('" + docNum + "','" + TextBox9.Text + "','" + Convert.ToDateTime(TextBox8.Text) + "'," + TextBox6.Text + "," + TextBox4.Text + "," + TextBox3.Text + ",'" + CheckBox1.Checked + "','False',N'" + DropDownList2.SelectedItem.Text + "','Normal'," + Session["UserID"].ToString() + ",'" + CheckBox5.Checked + "','"+ dtcustomer.Rows[0]["ID"].ToString() + "')");
                }
                for (int i = 0; i < dtDetail.Rows.Count; i++)
                {
                    code.DatabaseInsert(conn, "INSERT INTO [dbo].[Account_Receipt_Detail] ([Number],[Receipt_ID],[ProductType_ID],[Product_ID],[Product_Data],[Product_Amount],[Product_Unit],[Price_PerPeice],[Price_Amount]) VALUES (" + dtDetail.Rows[i]["Number"].ToString() + ",'" + docNum + "','" + dtDetail.Rows[i]["ProductType_ID"].ToString() + "',0,N'" + dtDetail.Rows[i]["Product_Data"].ToString() + "'," + dtDetail.Rows[i]["Product_Amount"].ToString() + ",N'" + dtDetail.Rows[i]["Product_Unit"].ToString() + "'," + dtDetail.Rows[i]["Price_PerPeice"].ToString() + "," + dtDetail.Rows[i]["Price_Amount"].ToString() + ")");

                }
                string path = System.Configuration.ConfigurationSettings.AppSettings["ReceiptFolderPath"].ToString();
                try
                {
                    System.IO.Directory.CreateDirectory(path + "\\" + Year);
                    System.IO.Directory.CreateDirectory(path + "\\" + Year + "\\" + Month);
                }
                catch (Exception ex)
                {

                }

                

                DataTable dtbusinessinfo = code.DatabaseQuery(conn, "Select * from Business_Info left join Customer_Type on Business_Type_ID = Customer_Type.ID left join Address on Address.ID = Address_ID");
                

                dtReceipt = code.DatabaseQuery(conn, "SELECT * FROM [Account_Receipt] left join Reservation on Reservation.ID = Reservation_ID Where Account_Receipt.ID = '" + RecNumber + "'");
                uid = dtReceipt.Rows[0]["UID"].ToString();
                DataTable dtReceiptDetail = code.DatabaseQuery(conn, "SELECT * FROM [Account_Receipt_Detail] inner join Account_ProductType on Account_ProductType.ID = ProductType_ID Where Receipt_ID = '" + RecNumber + "' order by Number ASC");


               
                //GridView1.DataSource = dt;
                //GridView1.DataBind();
               
                DataTable dtSignature = new DataTable();
                try
                {
                    dtSignature.Columns.Add("AuthorizeName");
                    dtSignature.Columns.Add("AuthorizeSignaturePath");
                    dtSignature.Columns.Add("CreatedName");
                    dtSignature.Columns.Add("CreatedSignaturePath");
                }
                catch { }
                
                string Signaturepath = System.Configuration.ConfigurationSettings.AppSettings["StaffSignatureFolderPath"].ToString();
                DataTable dtApprover = code.DatabaseQuery(conn, "Select * from Admin Where IsCEO = 'True'");
                string ApproverFullName = dtApprover.Rows[0]["FirstName"].ToString() + " " + dtApprover.Rows[0]["LastName"].ToString();

                DataTable dtCreator = code.DatabaseQuery(conn, "Select * from Admin Where ID = " + Session["UserID"].ToString());
                string CreatorFullName = dtCreator.Rows[0]["FirstName"].ToString() + " " + dtCreator.Rows[0]["LastName"].ToString();

                dtSignature.Rows.Add(ApproverFullName, "File:\\" + Signaturepath + "\\" + ApproverFullName.ToLower() + ".png", CreatorFullName,"File:\\"+Signaturepath+"\\"+CreatorFullName.ToLower()+".png");

                DataTable dtCustomerReport = new DataTable();
                dtCustomerReport = dtcustomer.Copy();
                DataTable dtBusinessinfoReport = new DataTable();
                dtBusinessinfoReport = dtbusinessinfo.Copy();

                try
                {
                    

                    if (CheckBox3.Checked == true)
                    {
                        dtCustomerReport.Rows[0]["FullName"] = "ประสงค์ไม่รับใบกำกับภาษี";
                        dtCustomerReport.Rows[0]["Address"] = "";
                        dtCustomerReport.Rows[0]["IDNumber"] = "";
                        dtCustomerReport.Rows[0]["MobilePhone"] = "";
                        dtCustomerReport.Rows[0]["Email"] = "";
                    }
                    else
                    {

                        dtcustomer.Rows[0]["PostalCode"] = TextBox16.Text;
                        if (DropDownList8.SelectedIndex == 0 && TextBox7.Text == "00000")
                        {
                            dtCustomerReport.Rows[0]["FullName"] = TextBox10.Text;
                        }
                        else if(DropDownList8.SelectedIndex == 0 && Convert.ToInt32(TextBox7.Text) > 0)
                        {
                            dtCustomerReport.Rows[0]["FullName"] = TextBox10.Text + " สาขาที่ "+TextBox7.Text ;
                        }
                        else
                        {
                            dtCustomerReport.Rows[0]["FullName"] = TextBox10.Text;
                        }
                        try
                        {
                            
                            if (dtcustomer.Rows[0]["PostalCode"].ToString().Substring(0, 2) == "10")
                            {
                                dtCustomerReport.Rows[0]["Address"] = TextBox11.Text + " " + TextBox18.Text + " แขวง " + DropDownList7.SelectedValue + " เขต " + DropDownList6.SelectedValue + " " + DropDownList5.SelectedValue + " " + dtcustomer.Rows[0]["PostalCode"].ToString();
                            }
                            else
                            {
                                dtCustomerReport.Rows[0]["Address"] = TextBox11.Text + " " + TextBox18.Text + " ต." + DropDownList7.SelectedValue + " อ." + DropDownList6.SelectedValue + " จ." + DropDownList5.SelectedValue + " " + dtcustomer.Rows[0]["PostalCode"].ToString();
                            }
                        }
                        catch
                        {
                            dtCustomerReport.Rows[0]["Address"] = dtcustomer.Rows[0]["Address"].ToString();
                        }

                        dtCustomerReport.Rows[0]["IDNumber"] = TextBox12.Text;
                        dtCustomerReport.Rows[0]["MobilePhone"] = TextBox13.Text;
                        dtCustomerReport.Rows[0]["Email"] = TextBox17.Text;
                    }
                    

                    try
                    {
                        if (dtbusinessinfo.Rows[0]["PostalCode"].ToString().Substring(0, 2) == "10")
                        {
                            dtBusinessinfoReport.Rows[0]["Address"] = dtbusinessinfo.Rows[0]["Address"].ToString() + " " + dtbusinessinfo.Rows[0]["Address1"].ToString() + " แขวง " + dtbusinessinfo.Rows[0]["SubDistrict"].ToString() + " เขต " + dtbusinessinfo.Rows[0]["District"].ToString() + " " + dtbusinessinfo.Rows[0]["Province"].ToString() + " " + dtbusinessinfo.Rows[0]["PostalCode"].ToString();
                        }
                        else
                        {
                            dtBusinessinfoReport.Rows[0]["Address"] = dtbusinessinfo.Rows[0]["Address"].ToString() + " " + dtbusinessinfo.Rows[0]["Address1"].ToString() + " ต." + dtbusinessinfo.Rows[0]["SubDistrict"].ToString() + " อ." + dtbusinessinfo.Rows[0]["District"].ToString() + " จ." + dtbusinessinfo.Rows[0]["Province"].ToString() + " " + dtbusinessinfo.Rows[0]["PostalCode"].ToString();
                        }
                    }
                    catch
                    {
                        dtBusinessinfoReport.Rows[0]["Address"] = dtbusinessinfo.Rows[0]["Address"].ToString();
                    }
                }
                catch { }

                try
                {
                    Account.Report.DataSet1 dataSet1 = new Account.Report.DataSet1();
                    dataSet1.Tables.Add(dtBusinessinfoReport);
                    ReportViewer2.LocalReport.DisplayName = "Receipt";
                    ReportViewer2.LocalReport.DataSources.Add(new ReportDataSource("DataSet1", dtBusinessinfoReport));
                    ReportViewer2.LocalReport.DataSources.Add(new ReportDataSource("DataSet2", dtCustomerReport));
                    ReportViewer2.LocalReport.DataSources.Add(new ReportDataSource("DataSet3", dtReceiptDetail));
                    ReportViewer2.LocalReport.DataSources.Add(new ReportDataSource("DataSet4", dtReceipt));
                    ReportViewer2.LocalReport.DataSources.Add(new ReportDataSource("DataSet5", dtSignature));
                    try
                    {

                   //     var deviceInfo = @"<DeviceInfo>
                   // <EmbedFonts>None</EmbedFonts>
                   //</DeviceInfo>";


                        Warning[] warnings;
                        string[] streamids;
                        string mimeType;
                        string encoding;
                        string filenameExtension;

                        byte[] bytes = ReportViewer2.LocalReport.Render(
                            "PDF", null, out mimeType, out encoding, out filenameExtension,
                            out streamids, out warnings);
                        if (File.Exists(path + "\\" + Year + "\\" + Month + "\\" + docNum + "_"+uid+".pdf"))
                        {
                            File.Delete(path + "\\" + Year + "\\" + Month + "\\" + docNum + "_" + uid + ".pdf");
                        }
                        if (File.Exists(path + "\\" + Year + "\\" + Month + "\\" + docNum +  ".pdf"))
                        {
                            File.Delete(path + "\\" + Year + "\\" + Month + "\\" + docNum + ".pdf");
                        }
                        using (FileStream fs = new FileStream(path + "\\" + Year + "\\" + Month + "\\" + docNum + "_" + uid + ".pdf", FileMode.Append))
                        { 
                            fs.Write(bytes, 0, bytes.Length);
                        }
                    }
                    catch (Exception ex)
                    {
                    }

                    if (CheckBox5.Checked == true)
                    {
                        try
                        {
                            string xmlFilePath = path + "\\" + Year + "\\" + Month + "\\" + docNum + "_" + uid + ".xml";
                            string xmlString = System.IO.File.ReadAllText(ConfigurationSettings.AppSettings["BaseFolderPath"].ToString() + "\\Resources\\template.xml");
                            xmlString = xmlString.Replace("*invoice_id", docNum);
                            xmlString = xmlString.Replace("*invoice_name", "ใบเสร็จรับเงิน/ใบกำกับภาษี");
                            xmlString = xmlString.Replace("*invoice_typecode", "T03");
                            xmlString = xmlString.Replace("*invoice_issue_date", Convert.ToDateTime(dtReceipt.Rows[0]["Created_Date"].ToString()).ToString("yyyy-MM-dd") + "T00:00:00.000");
                            xmlString = xmlString.Replace("*invoice_purpose", "");
                            xmlString = xmlString.Replace("*invoice_Purpose_code", "");
                            xmlString = xmlString.Replace("*invoice_create_date", Convert.ToDateTime(dtReceipt.Rows[0]["Created_Date"].ToString()).ToString("yyyy-MM-dd") + "T00:00:00.000");
                            xmlString = xmlString.Replace("*invoice_remark", "");

                            try
                            {
                                xmlString = xmlString.Replace("*seller_type", dtbusinessinfo.Rows[0]["Customer_Code"].ToString());
                                if (dtbusinessinfo.Rows[0]["Customer_Code"].ToString() == "TXID")
                                {
                                    xmlString = xmlString.Replace("*seller_taxid", dtbusinessinfo.Rows[0]["LegalEntity_Number"].ToString() + dtbusinessinfo.Rows[0]["Branch_Number"].ToString());
                                }
                                else
                                {
                                    xmlString = xmlString.Replace("*seller_taxid", dtbusinessinfo.Rows[0]["LegalEntity_Number"].ToString());
                                }
                            }
                            catch
                            {
                                xmlString = xmlString.Replace("*seller_type", "TXID");
                                xmlString = xmlString.Replace("*seller_taxid", dtbusinessinfo.Rows[0]["LegalEntity_Number"].ToString());
                            }

                            xmlString = xmlString.Replace("*seller_name", dtbusinessinfo.Rows[0]["Company_Name"].ToString());

                            xmlString = xmlString.Replace("*seller_DefinedCITradeContact", dtbusinessinfo.Rows[0]["Email"].ToString());
                            xmlString = xmlString.Replace("*seller_PhoneNumber", dtbusinessinfo.Rows[0]["Phone_Number"].ToString());
                            xmlString = xmlString.Replace("*seller_zipcode", dtbusinessinfo.Rows[0]["PostalCode"].ToString());
                            xmlString = xmlString.Replace("*seller_address1", dtbusinessinfo.Rows[0]["Address"].ToString() + " " + dtbusinessinfo.Rows[0]["Address1"].ToString() + " " + dtbusinessinfo.Rows[0]["SubDistrict"].ToString() + " " + dtbusinessinfo.Rows[0]["District"].ToString() + " " + dtbusinessinfo.Rows[0]["Province"].ToString() + " " + dtbusinessinfo.Rows[0]["PostalCode"].ToString());
                            xmlString = xmlString.Replace("*seller_address2", "");
                            xmlString = xmlString.Replace("*seller_cityname", dtbusinessinfo.Rows[0]["Address_Code"].ToString().Substring(0, 4));
                            xmlString = xmlString.Replace("*seller_city_subdivision_name", dtbusinessinfo.Rows[0]["Address_Code"].ToString().Substring(0, 6));
                            xmlString = xmlString.Replace("*seller_country", "TH");
                            xmlString = xmlString.Replace("*sellercountry_subdivision_id", dtbusinessinfo.Rows[0]["Address_Code"].ToString().Substring(0, 2));
                            xmlString = xmlString.Replace("*seller_building_name", dtbusinessinfo.Rows[0]["Address"].ToString());
                            xmlString = xmlString.Replace("*buyer_name", dtcustomer.Rows[0]["FullName"].ToString());

                            try
                            {


                                xmlString = xmlString.Replace("*buyer_taxtype", dtcustomer.Rows[0]["Customer_Code"].ToString());
                                

                                if (dtcustomer.Rows[0]["Customer_Code"].ToString() == "TXID")
                                {
                                    string bnumber = "00000";
                                    if (TextBox7.Text.Length == 5)
                                    {
                                        bnumber = dtcustomer.Rows[0]["Branch_Number"].ToString();
                                    }
                                    xmlString = xmlString.Replace("*buyer_taxid", dtcustomer.Rows[0]["IDNumber"].ToString() + bnumber);
                                }
                                else
                                {
                                    xmlString = xmlString.Replace("*buyer_taxtype", "NIDN");
                                    xmlString = xmlString.Replace("*buyer_taxid", dtcustomer.Rows[0]["IDNumber"].ToString());
                                }
                            }
                            catch
                            {
                                xmlString = xmlString.Replace("*buyer_taxtype", "NIDN");
                                xmlString = xmlString.Replace("*buyer_taxid", dtcustomer.Rows[0]["IDNumber"].ToString());
                            }


                            xmlString = xmlString.Replace("*buyer_DefinedCITradeContact", TextBox17.Text);
                            xmlString = xmlString.Replace("*buyer_zipcode", dtcustomer.Rows[0]["PostalCode"].ToString());
                            xmlString = xmlString.Replace("*buyer_address", dtcustomer.Rows[0]["Address"].ToString() +" "+ dtcustomer.Rows[0]["Address1"].ToString()+ " "+ dtcustomer.Rows[0]["SubDistrict"].ToString() + " " + dtcustomer.Rows[0]["District"].ToString()+ " " + dtcustomer.Rows[0]["Province"].ToString()+ " " + dtcustomer.Rows[0]["PostalCode"].ToString());
                            xmlString = xmlString.Replace("*buyer_address2", "");
                            xmlString = xmlString.Replace("*buyer_cityname", dtcustomer.Rows[0]["Address_Code"].ToString().Substring(0, 4));
                            xmlString = xmlString.Replace("*buyer_city_subdivision_name", dtcustomer.Rows[0]["Address_Code"].ToString().Substring(0, 6));
                            xmlString = xmlString.Replace("*buyer_country", "TH");
                            xmlString = xmlString.Replace("*buyercountry_subdivision_id", dtcustomer.Rows[0]["Address_Code"].ToString().Substring(0, 2));
                            xmlString = xmlString.Replace("*buyer_building_name", dtcustomer.Rows[0]["Address"].ToString());
                            xmlString = xmlString.Replace("*reference", "");
                            xmlString = xmlString.Replace("*buyer_contact_person", "");
                            xmlString = xmlString.Replace("*currency", "THB");
                            xmlString = xmlString.Replace("*invoice_tax_code", "VAT");
                            xmlString = xmlString.Replace("*invoice_tax_rate", "7");
                            xmlString = xmlString.Replace("*invoice_basis_amount", dtReceipt.Rows[0]["Total_Amount_Exclude_Vat"].ToString());
                            xmlString = xmlString.Replace("*calculated_amount", dtReceipt.Rows[0]["Vat"].ToString());
                            xmlString = xmlString.Replace("*invoice_discountallowance", "");
                            xmlString = xmlString.Replace("*invoice_serviceallowance", "");
                            xmlString = xmlString.Replace("*invoice_line_total", dtReceipt.Rows[0]["Total_Amount_Exclude_Vat"].ToString());
                            xmlString = xmlString.Replace("*tax_basis_total_amount", dtReceipt.Rows[0]["Total_Amount_Exclude_Vat"].ToString());
                            xmlString = xmlString.Replace("*invoice_tax_total", dtReceipt.Rows[0]["Vat"].ToString());
                            xmlString = xmlString.Replace("*invoice_grand_total", dtReceipt.Rows[0]["Total_Amount"].ToString());
                            xmlString = xmlString.Replace("*item", "ค่าที่พักหรือค่ามัดจำที่พัก");
                            xmlString = xmlString.Replace("*invoice_billedquantity", "1");

                            System.IO.File.WriteAllText(xmlFilePath, xmlString, System.Text.Encoding.UTF8);
                        }
                        catch { }

                        try
                        {
                            {


                                PDFA3Invoice pdf = new PDFA3Invoice();
                                string pdfFilePath = path + "\\" + Year + "\\" + Month + "\\" + docNum + "_" + uid + ".pdf";
                                string xmlFilePath = path + "\\" + Year + "\\" + Month + "\\" + docNum + "_" + uid + ".xml";

                                string xmlFileName = "ETDA-invoice.xml";


                                string xmlVersion = "1.0";
                                string documentID = docNum;
                                string documentOID = "";

                                string outputPath = path + "\\" + Year + "\\" + Month + "\\" + docNum + "_" + uid + "_etax.pdf";

                                pdf.CreatePDFA3Invoice(pdfFilePath, xmlFilePath, xmlFileName, xmlVersion, documentID, documentOID, outputPath, "Tax Invoice");

                                if (CheckBox5.Checked == true)
                                {

                                    DateTime docDate = DateTime.Now;

                                    try
                                    {
                                        if (Convert.ToDateTime(TextBox8.Text) < docDate)
                                        {
                                            docDate = Convert.ToDateTime(TextBox8.Text);
                                        }
                                    }
                                    catch
                                    {

                                    }
                                    //DataTable dtReceipt = code.DatabaseQuery(conn, "SELECT  [ID] FROM [Account_Receipt] Where RESERVATION_ID = '" + Reservation_ID + "'");

                                    //string path = System.Configuration.ConfigurationSettings.AppSettings["ReceiptFolderPath"].ToString();
                                    //string pdfpath = path + "\\" + docDate.Year.ToString() + "\\" + docDate.Month.ToString() + "\\" + dtReceipt.Rows[0]["ID"].ToString() + "_etax.pdf";

                                    //string pdfFilePath = pdfpath;
                                    byte[] bytes = System.IO.File.ReadAllBytes(outputPath);
                                    Attachment[] dataall = new Attachment[1];
                                    MemoryStream pdf2 = new MemoryStream(bytes);
                                    Attachment data = new Attachment(pdf2, dtReceipt.Rows[0]["ID"].ToString() + "_" + uid + "_etax.pdf");
                                    dataall[0] = data;

                                    string docCreateThaiDate = "";

                                    if (docDate.Day.ToString().Length > 1)
                                    {
                                        docCreateThaiDate += docDate.Day.ToString();
                                    }
                                    else
                                    {
                                        docCreateThaiDate += "0" + docDate.Day.ToString();
                                    }

                                    if (docDate.Month.ToString().Length > 1)
                                    {
                                        docCreateThaiDate += docDate.Month.ToString();
                                    }
                                    else
                                    {
                                        docCreateThaiDate += "0" + docDate.Month.ToString();
                                    }


                                    if (Convert.ToInt32(docDate.Year.ToString()) > 2500)
                                    {
                                        docCreateThaiDate += docDate.Year.ToString();
                                    }
                                    else
                                    {
                                        docCreateThaiDate += (Convert.ToInt32(docDate.Year.ToString()) + 543).ToString();
                                    }



                                    string subject = "[" + docCreateThaiDate + "][INV][" + dtReceipt.Rows[0]["ID"].ToString() + "]";
                                    string body = "เรียน ลูกค้าผู้มีอุปการะคุณ <br /><br /> หจก.แอม แฮปปี้เนส (Take Time) ได้แนบใบกำกับภาษี/ใบเสร็จรับเงินมาพร้อมกับอีเมล์ฉบับนี้ ท่านสามารถเปิดดูได้โดยคลิกไฟล์แนบ (PDF File)<br />ขอแสดงความนับถือ<br /> หจก.แอม แฮปปี้เนส (Take Time) ";

                                    Reservation rs = new Reservation();
                                    rs.SendEmail(ConfigurationSettings.AppSettings["SMTP"].ToString(), Convert.ToInt32(ConfigurationSettings.AppSettings["SMTP_Port"].ToString()), Convert.ToBoolean(ConfigurationSettings.AppSettings["SMTP_EnableSsl"].ToString()), Convert.ToBoolean(ConfigurationSettings.AppSettings["SMTP_UseDefaultCredentials"].ToString()), ConfigurationSettings.AppSettings["Email_From"].ToString(), ConfigurationSettings.AppSettings["Email_Password_From"].ToString(), TextBox17.Text, ConfigurationSettings.AppSettings["Email_CC"].ToString(), subject, body, dataall);


                                }
                            }
                            }
                        catch
                        {

                        }
                        //ReportViewer2.LocalReport.Refresh();

                    }
                    }

                catch { }


                Response.Redirect("/Account/Receipt");
            }
            else
            {
                ClientScript.RegisterStartupScript(this.GetType(), "myalert", "alert('กรุณาระบุข้อมูลให้ครบถ้วน');", true);
            }
            
        }

        public string cleantext(string input)
        {
            string output = input.Replace(",", "").Replace("'", "").Replace("\"", "");
            return output;
        }

        protected void Button4_Click(object sender, EventArgs e)
        {
            
          
        }

        protected void GridView2_RowDeleted(object sender, GridViewDeletedEventArgs e)
        {
        }

        protected void GridView2_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {
          
        }

        protected void TextBox9_TextChanged(object sender, EventArgs e)
        {
            if(TextBox9.Text.Length > 0)
            {
                DataTable dtCustomer = code.DatabaseQuery(conn, "SELECT * FROM [Reservation] inner join Customer on Customer.MobilePhone = Reservation.Customer_MobilePhone Where Reservation.ID = "+TextBox9.Text);
                if(dtCustomer.Rows.Count > 0)
                {
                    TextBox10.Text = dtCustomer.Rows[0]["FullName"].ToString();
                    TextBox11.Text = dtCustomer.Rows[0]["Address"].ToString();
                    TextBox12.Text = dtCustomer.Rows[0]["IDNumber"].ToString();
                    TextBox13.Text = dtCustomer.Rows[0]["MobilePhone"].ToString();
                }
            }

        }

        protected void CheckBox2_CheckedChanged(object sender, EventArgs e)
        {
            if(CheckBox2.Checked == true)
            {
                TextBox5.Enabled = true;
            }
            else
            {
                TextBox5.Enabled = false;
            }
        }

        protected void CheckBox3_CheckedChanged(object sender, EventArgs e)
        {
            if(CheckBox3.Checked == true)
            {
                
               // TextBox10.Text = "ประสงค์ไม่รับใบกำกับภาษี";
               // TextBox11.Text = "";
               // TextBox12.Text = "";
               // TextBox13.Text = "";
            }
        }

        protected void CheckBox4_CheckedChanged(object sender, EventArgs e)
        {
            if(CheckBox4.Checked == true)
            {
                Button4.Enabled = true;
            }
            else
            {
                Button4.Enabled = false;
            }
        }

        protected void Button4_Click1(object sender, EventArgs e)
        {
            string uid = Request.QueryString["uid"];
            string path = ConfigurationSettings.AppSettings["ReceiptFolderPath"].ToString();
            string Imagespath = ConfigurationSettings.AppSettings["ImagesFolderPath"].ToString();
            DataTable dtRec = code.DatabaseQuery(conn, "Select * from Account_Receipt Where Status = 'Normal' AND UID = '" + uid + "'");
            string id = dtRec.Rows[0]["ID"].ToString();
            for (int i = 0; i < dtRec.Rows.Count; i++)
            {
                code.DatabaseInsert(conn, "UPDATE [dbo].[Account_Receipt] SET[Status] = 'Cancel' WHERE ID = '" + id + "'");

                DateTime createdDate = Convert.ToDateTime(dtRec.Rows[i]["Created_Date"].ToString());

                string inputPdfStreampath = "";
                string outputPdfStreampath = "";
                if(File.Exists(path + "\\" + createdDate.Year.ToString() + "\\" + createdDate.Month + "\\" + dtRec.Rows[i]["ID"].ToString() + "_"+uid+".pdf"))
                {
                    inputPdfStreampath = path + "\\" + createdDate.Year.ToString() + "\\" + createdDate.Month + "\\" + dtRec.Rows[i]["ID"].ToString() + "_" + uid + ".pdf";
                }
                else
                {
                    inputPdfStreampath = path + "\\" + createdDate.Year.ToString() + "\\" + createdDate.Month + "\\" + dtRec.Rows[i]["ID"].ToString() + ".pdf";
                }

                if (File.Exists(path + "\\" + createdDate.Year.ToString() + "\\" + createdDate.Month + "\\" + dtRec.Rows[i]["ID"].ToString() +"_"+uid+ "_Cancel.pdf"))
                {
                    outputPdfStreampath = path + "\\" + createdDate.Year.ToString() + "\\" + createdDate.Month + "\\" + dtRec.Rows[i]["ID"].ToString() + "_" + uid + "_Cancel.pdf";
                }
                else
                {
                    outputPdfStreampath = path + "\\" + createdDate.Year.ToString() + "\\" + createdDate.Month + "\\" + dtRec.Rows[i]["ID"].ToString() + "_Cancel.pdf";
                }
                using (Stream inputPdfStream = new FileStream(inputPdfStreampath, FileMode.Open, FileAccess.Read, FileShare.Read))
                    using (Stream inputImageStream = new FileStream(Imagespath + "\\Cancel.png", FileMode.Open, FileAccess.Read, FileShare.Read))
                    using (Stream outputPdfStream = new FileStream(outputPdfStreampath, FileMode.Append, FileAccess.Write, FileShare.None))
                    {
                        var reader = new PdfReader(inputPdfStream);
                        var stamper = new PdfStamper(reader, outputPdfStream);
                        var pdfContentByte = stamper.GetOverContent(1);

                        iTextSharp.text.Image image = iTextSharp.text.Image.GetInstance(inputImageStream);
                        image.SetAbsolutePosition(100, 100);
                        pdfContentByte.AddImage(image);
                        stamper.Close();
                    }
                File.Delete(inputPdfStreampath);
                try
                {
                    File.Delete(inputPdfStreampath + "_etax.pdf");
                }
                catch
                {

                }

                Response.Redirect("/Account/Receipt");
            }
        }

        protected void Button5_Click(object sender, EventArgs e)
        {
            TextBox16.Enabled = false;
            getAddress("SELECT DISTINCT [Province] FROM [Address] Where PostalCode = '" + TextBox16.Text + "' order by Province ASC", "SELECT DISTINCT [District] FROM [Address] Where PostalCode = '" + TextBox16.Text + "' order by District ASC", "SELECT DISTINCT [SubDistrict] FROM [Address] Where PostalCode = '" + TextBox16.Text + "' order by SubDistrict ASC");
        }

        public void getAddress(string commp, string commd, string commsd)
        {
            string Command = Request.QueryString["Command"];
            string ID = Request.QueryString["ID"];
            DataTable dtProvince = code.DatabaseQuery(conn, commp);
            DataTable dtDistrict = code.DatabaseQuery(conn, commd);
            DataTable dtSubDistrict = code.DatabaseQuery(conn, commsd);
            try
            {
                if (dtProvince.Rows.Count <= 0)
                {
                    ClientScript.RegisterStartupScript(this.GetType(), "myalert", "alert('ไม่พบหมายเลขไปรษณีย์ที่คุณระบุ');", true);
                    TextBox16.Enabled = true;
                }
                else
                {
                    if (Button2.Enabled == true || Command == "View" || Command == "Edit")
                    {
                        List<string> ddl = new List<string>();

                        for (int i = 0; i < dtProvince.Rows.Count; i++)
                        {
                            ddl.Add(dtProvince.Rows[i][0].ToString());
                        }
                        DropDownList5.DataSource = ddl;
                        DropDownList5.DataBind();
                        //DropDownList5.SelectedIndex = 0;

                        ddl.Clear();

                        for (int i = 0; i < dtDistrict.Rows.Count; i++)
                        {
                            ddl.Add(dtDistrict.Rows[i][0].ToString());
                        }
                        DropDownList6.DataSource = ddl;
                        DropDownList6.DataBind();
                        //DropDownList6.SelectedIndex = 0;

                        ddl.Clear();

                        for (int i = 0; i < dtSubDistrict.Rows.Count; i++)
                        {
                            ddl.Add(dtSubDistrict.Rows[i][0].ToString());
                        }
                        DropDownList7.DataSource = ddl;
                        DropDownList7.DataBind();
                        //DropDownList7.SelectedIndex = 0;
                    }
                    else { }
                }
            }
            catch { }
        }

        protected void TextBox16_TextChanged(object sender, EventArgs e)
        {
            Button5_Click(null, null);
        }

        protected void Button6_Click(object sender, EventArgs e)
        {
            TextBox16.Enabled = true;
            TextBox16.Text = string.Empty;
            DropDownList5.Items.Clear();
            DropDownList6.Items.Clear();
            DropDownList7.Items.Clear();
        }

        public string CheckAddressID(string ZipCode,string Province,string District,string SubDistrict)
        {
            string ID = "0";

            try
            {
                DataTable dt = code.DatabaseQuery(conn, "Select ID from Address Where PostalCode = '" + ZipCode + "' AND Province = N'" + Province + "' AND District = N'" + District + "' AND SubDistrict = N'" + SubDistrict + "'");
                ID = dt.Rows[0][0].ToString();
            }
            catch { }

            return ID;
        }

        protected void DropDownList8_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (DropDownList8.SelectedValue == "1")
            {
                TextBox7.Visible = true;
            }
            else
            {
                TextBox7.Visible = false;
            }
        }

        protected void DropDownList5_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (TextBox16.Enabled == false)
            {
                getAddress("SELECT DISTINCT [Province] FROM [Address] Where PostalCode = '" + TextBox16.Text + "' AND Province = N'" + DropDownList5.SelectedValue + "' order by Province ASC", "SELECT DISTINCT [District] FROM [Address] Where PostalCode = '" + TextBox16.Text + "' AND Province = N'" + DropDownList5.SelectedValue + "' order by District ASC", "SELECT DISTINCT [SubDistrict] FROM [Address] Where PostalCode = '" + TextBox16.Text + "' AND Province = N'" + DropDownList5.SelectedValue + "' order by SubDistrict ASC");
            }
            else
            {
                getAddress("SELECT DISTINCT [Province] FROM [Address] Where Province = N'" + DropDownList5.SelectedValue + "' order by Province ASC", "SELECT DISTINCT [District] FROM [Address] Where Province = N'" + DropDownList5.SelectedValue + "' order by District ASC", "SELECT DISTINCT [SubDistrict] FROM [Address] Where Province = N'" + DropDownList5.SelectedValue + "' order by SubDistrict ASC");
            }
        }

        protected void DropDownList6_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (TextBox16.Enabled == false)
            {
                getAddress("SELECT DISTINCT [Province] FROM [Address] Where PostalCode = '" + TextBox16.Text + "' AND District = N'" + DropDownList6.SelectedValue + "' order by Province ASC", "SELECT DISTINCT [District] FROM [Address] Where PostalCode = '" + TextBox16.Text + "' AND District = N'" + DropDownList6.SelectedValue + "' order by District ASC", "SELECT DISTINCT [SubDistrict] FROM [Address] Where PostalCode = '" + TextBox16.Text + "' AND District = N'" + DropDownList6.SelectedValue + "' order by SubDistrict ASC");
            }
            else
            {
                getAddress("SELECT DISTINCT [Province] FROM [Address] Where District = N'" + DropDownList6.SelectedValue + "' order by Province ASC", "SELECT DISTINCT [District] FROM [Address] Where District = N'" + DropDownList6.SelectedValue + "' order by District ASC", "SELECT DISTINCT [SubDistrict] FROM [Address] Where District = N'" + DropDownList6.SelectedValue + "' order by SubDistrict ASC");
            }
        }

        protected void CheckBox5_CheckedChanged(object sender, EventArgs e)
        {
            if (CheckBox5.Checked == true)
            {
               if(TextBox17.Text.Length <= 0)
                {
                    CheckBox5.Checked = false;
                }
               // TextBox10.Text = "ประสงค์ไม่รับใบกำกับภาษี";
               // TextBox11.Text = "";
               // TextBox12.Text = "";
               // TextBox13.Text = "";
            }
            else
            {
                
            }
        }
    }
}