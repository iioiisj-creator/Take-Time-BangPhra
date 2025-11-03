// CustomerService.cs
using System.Data;
using Take_Time_BangPhra.Helpers;

namespace Take_Time_BangPhra.Services
{
    public class CustomerService
    {
        private readonly DatabaseHelper _dbHelper;

        public CustomerService()
        {
            _dbHelper = new DatabaseHelper();
        }

        public DataTable GetCustomerByPhone(string phoneNumber)
        {
            string query = $"SELECT * FROM Customer LEFT JOIN Customer_Type ON Customer_Type_ID = Customer_Type.ID LEFT JOIN Address ON Address.ID = Address_ID WHERE MobilePhone = '{phoneNumber}'";
            return _dbHelper.ExecuteQuery(query);
        }

        public DataTable GetCustomerReservationHistory(string phoneNumber)
        {
            string query = $"SELECT COUNT([Customer_MobilePhone]) as CountReserved FROM [Reservation] WHERE Customer_MobilePhone = '{phoneNumber}' AND Status = N'เช็คอินแล้ว'";
            return _dbHelper.ExecuteQuery(query);
        }

        public DataTable GetCustomerTypes()
        {
            string query = "SELECT [Customer_Type], ID FROM Customer_Type";
            return _dbHelper.ExecuteQuery(query);
        }

        public DataTable GetCustomerByReservation(string reservationId)
        {
            string query = $"SELECT Customer.MobilePhone FROM [Reservation] inner join Customer on Customer.MobilePhone = Reservation.Customer_MobilePhone Where Reservation.ID = {reservationId}";
            return _dbHelper.ExecuteQuery(query);
        }
    }
}