using System;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using System.Web;

namespace Take_Time_BangPhra
{
    public class TelegramBot2
    {
        private readonly string _botToken;
        private readonly HttpClient _httpClient;

        public TelegramBot2(string botToken)
        {
            _botToken = botToken;
            _httpClient = new HttpClient();
            _httpClient.Timeout = TimeSpan.FromSeconds(30);
        }

        public async Task SendMessageAsync(string chatId, string message)
        {
            try
            {
                // Simple HTTP implementation without RestSharp
                string url = string.Format("https://api.telegram.org/bot{0}/sendMessage", _botToken);

                var payload = new
                {
                    chat_id = chatId,
                    text = message,
                    parse_mode = "HTML"
                };

                string jsonPayload = Newtonsoft.Json.JsonConvert.SerializeObject(payload);
                var content = new StringContent(jsonPayload, Encoding.UTF8, "application/json");

                var response = await _httpClient.PostAsync(url, content);

                if (!response.IsSuccessStatusCode)
                {
                    string errorContent = await response.Content.ReadAsStringAsync();
                    System.Diagnostics.Trace.TraceError(string.Format("Telegram API error: {0} - {1}", response.StatusCode, errorContent));
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Trace.TraceError(string.Format("Telegram send error: {0}", ex.Message));
                // Don't throw - telegram failure shouldn't break the main reservation process
            }
        }

        public async Task SendMediaAsync(string chatId, string caption, byte[] fileBytes, string filename, string contentType)
        {
            try
            {
                // Simple implementation for media upload
                string url = string.Format("https://api.telegram.org/bot{0}/sendDocument", _botToken);

                using (var form = new MultipartFormDataContent())
                {
                    form.Add(new StringContent(chatId), "chat_id");
                    form.Add(new StringContent(caption), "caption");

                    var fileContent = new ByteArrayContent(fileBytes);
                    fileContent.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue(contentType);
                    form.Add(fileContent, "document", filename);

                    var response = await _httpClient.PostAsync(url, form);

                    if (!response.IsSuccessStatusCode)
                    {
                        string errorContent = await response.Content.ReadAsStringAsync();
                        System.Diagnostics.Trace.TraceError(string.Format("Telegram media API error: {0} - {1}", response.StatusCode, errorContent));
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Trace.TraceError(string.Format("Telegram media send error: {0}", ex.Message));
            }
        }

        public void Dispose()
        {
            _httpClient?.Dispose();
        }
    }
}
