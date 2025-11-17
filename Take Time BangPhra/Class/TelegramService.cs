// TelegramService.cs
using System;
using System.Configuration;
using System.Data;
using System.Threading.Tasks;

namespace Take_Time_BangPhra.Services
{
    public class TelegramService
    {
        private readonly string _botToken;

        public TelegramService()
        {
            _botToken = ConfigurationManager.AppSettings["TelegramTokenTakeTime"];
        }

        public TelegramService(string botToken)
        {
            _botToken = botToken;
        }

        public async Task<bool> SendMessageAsync(string chatId, string message)
        {
            try
            {
                if (string.IsNullOrEmpty(_botToken))
                {
                    System.Diagnostics.Trace.TraceError("Telegram token is missing");
                    return false;
                }

                var bot = new TelegramBot2(_botToken);
                await bot.SendMessageAsync(chatId, message);
                System.Diagnostics.Trace.TraceInformation(string.Format("Telegram message sent to {0}", chatId));
                return true;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Trace.TraceError(string.Format("Telegram send error: {0}", ex.Message));
                return false;
            }
        }

        public async Task SendReservationNotificationAsync(string reservationId, string phoneNumber,
            DateTime checkinDate, DateTime checkoutDate, string details)
        {
            string message = string.Format("ลูกค้าจองห้องพักใหม่หมายเลขการจอง: {0}\r\n", reservationId) +
                           string.Format("หมายเลขโทรศัพท์: {0}\r\n", phoneNumber) +
                           string.Format("เช็คอินวันที่: {0}\r\n", checkinDate:dd MMMM yyyy) +
                           string.Format("เช็คเอ้าท์วันที่: {0}\r\n", checkoutDate:dd MMMM yyyy) +
                           string.Format("{0}", details);

            await SendMessageAsync("-4969611371", message);
        }

        public async Task SendCancellationNotificationAsync(string reservationId, DataTable reservationDetails)
        {
            string message = "ยกเลิกการจอง:\r\n";
            for (int i = 0; i < reservationDetails.Rows.Count; i++)
            {
                DateTime checkinDate = DateTime.Parse(reservationDetails.Rows[i]["CheckinDate"].ToString());
                message += string.Format("- หมายเลข: {0}\r\n", reservationId) +
                          "ห้องพัก: {reservationDetails.Rows[i]["AccomName"]}\r\n" +
                          string.Format("เช็คอิน: {0}\r\n", checkinDate:dd MMMM yyyy) +
                          "เช็คเอาท์: {reservationDetails.Rows[i]["CheckOutDate"]}\r\n" +
                          "จำนวนคืน: {reservationDetails.Rows[i]["StayDays"]}\r\n\r\n";
            }

            await SendMessageAsync("-4969611371", message);
        }

        public async Task SendEditNotificationAsync(string reservationId, string phoneNumber,
            DateTime checkinDate, DateTime checkoutDate, string details)
        {
            string message = string.Format("แก้ไขการจองหมายเลข: {0}\r\n", reservationId) +
                           string.Format("หมายเลขโทรศัพท์: {0}\r\n", phoneNumber) +
                           string.Format("เช็คอินวันที่: {0}\r\n", checkinDate:dd MMMM yyyy) +
                           string.Format("เช็คเอ้าท์วันที่: {0}\r\n", checkoutDate:dd MMMM yyyy) +
                           string.Format("{0}", details);

            await SendMessageAsync("-4969611371", message);
        }
    }
}
