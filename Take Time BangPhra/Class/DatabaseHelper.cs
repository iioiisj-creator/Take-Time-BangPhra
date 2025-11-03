// DatabaseHelper.cs
using System;
using System.Data;
using System.Data.SqlClient;
using System.Configuration;
using System.Globalization;
using System.Collections.Generic;

namespace Take_Time_BangPhra.Helpers
{
    public class DatabaseHelper
    {
        private readonly string _connectionString;

        public DatabaseHelper()
        {
            _connectionString = ConfigurationManager.ConnectionStrings["TaketimeConnectionString"].ConnectionString;
        }

        public DatabaseHelper(string connectionString)
        {
            _connectionString = connectionString;
        }

        public string ConnectionString
        {
            get { return _connectionString; }
        }

        public int ExecuteInsert(string sqlCommand)
        {
            int id = 0;
            using (SqlConnection connection = new SqlConnection(_connectionString))
            using (SqlCommand command = new SqlCommand(CleanSqlCommand(sqlCommand), connection))
            {
                // Match the old method exactly
                string cmd = sqlCommand.Replace("&nbsp;", "");
                connection.Open();
                try
                {
                    var result = command.ExecuteScalar();
                    if (result != null && result != DBNull.Value)
                    {
                        id = Convert.ToInt32(result);
                    }
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Trace.TraceError($"Database insert error: {ex.Message}");
                    // Don't throw, match old behavior
                }
            }
            return id;
        }

        public DataTable ExecuteQuery(string sqlCommand)
        {
            DataTable dt = new DataTable();
            using (SqlConnection con = new SqlConnection(_connectionString))
            {
                try
                {
                    // Match the old cleaning exactly
                    string cmd = sqlCommand.Replace("&amp;", "&");
                    cmd = cmd.Replace("&#39;", "''");
                    cmd = cmd.Replace("&nbsp;", "");

                    SqlDataAdapter adapter = new SqlDataAdapter(cmd, con);
                    adapter.Fill(dt);
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Trace.TraceError($"Database query error: {ex.Message}");
                    // Don't throw, match old behavior
                }
            }
            return dt;
        }
        public DataTable ExecuteQueryWithParams(string query, Dictionary<string, object> parameters = null)
        {
            DataTable dt = new DataTable();
            using (SqlConnection conn = new SqlConnection(_connectionString))
            {
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    if (parameters != null)
                    {
                        foreach (var param in parameters)
                        {
                            cmd.Parameters.AddWithValue(param.Key, param.Value ?? DBNull.Value);
                        }
                    }

                    conn.Open();
                    using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        da.Fill(dt);
                    }
                }
            }
            return dt;
        }

        private string CleanSqlCommand(string command)
        {
            return command?.Replace("&amp;", "&")
                         .Replace("&#39;", "''")
                         .Replace("&nbsp;", "")
                         .Replace("'", "''") ?? string.Empty;
        }

        public string GenerateDocumentNumber(string tableName, string docType, DateTime documentDate)
        {
            string year = documentDate.Year.ToString().Substring(2);
            string month = documentDate.Month.ToString("00");
            string day = documentDate.Day.ToString("00");

            string query = $"SELECT TOP 1 ID FROM {tableName} WHERE ID LIKE '{docType}{year}{month}{day}%' ORDER BY ID DESC";
            DataTable dt = ExecuteQuery(query);

            int nextNumber = 1;
            if (dt.Rows.Count > 0)
            {
                string lastNumber = dt.Rows[0][0].ToString();
                if (lastNumber.Length >= 3)
                {
                    string lastThree = lastNumber.Substring(lastNumber.Length - 3);
                    nextNumber = Convert.ToInt32(lastThree) + 1;
                }
            }

            string numberStr = nextNumber.ToString("000");
            return $"{docType}{year}{month}{day}{numberStr}";
        }
    }
}