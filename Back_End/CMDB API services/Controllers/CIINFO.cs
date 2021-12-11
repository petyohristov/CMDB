using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
//using System.Configuration;
using Microsoft.Extensions.Configuration;
using System.Data.SqlClient;
using System.Data;
using Microsoft.AspNetCore.Cors;
using System.Text;


// For more information on enabling Web API for empty projects, visit https://go.microsoft.com/fwlink/?LinkID=397860

namespace CMDB_API_services.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class CIINFO : ControllerBase
    {
        private readonly IConfiguration Configuration;

        public CIINFO(IConfiguration configuration)
        {
            Configuration = configuration;
        }


        // GET: api/<CMDB>
        [HttpGet]
        public string Get()
        {

            string con = Configuration["ConnectionStrings:CMDBConnString"];//"Data Source=itadmin;Initial Catalog=CMDB;Persist Security Info=True;User ID=sa;Password=AquaT1nta";
            string retJson = "{}";

            using (var conn = new SqlConnection(con))
            {
                using (var cmd = new SqlCommand("Select dbo.fn_Json_v2(@PersonId, @IsRoot)", conn))
                {
                    cmd.CommandTimeout = 30;

                    cmd.Parameters.AddWithValue("@PersonId", 154);
                    cmd.Parameters.AddWithValue("@IsRoot", 1);

                    conn.Open();

                    SqlDataReader reader = cmd.ExecuteReader();

                    StringBuilder sb = new StringBuilder(); 
                    while (reader.Read()) sb.Append(reader.GetSqlString(0).Value);

                    string getValue = sb.ToString();
                    if (getValue != null)
                    {
                        retJson = getValue.ToString();
                    }

                    conn.Close();
                    return retJson;
                }
            }
            
            
        }

        // GET api/<CMDB>/5
        [HttpGet("{id}")]
        public string Get(int id)
        {

            string con = Configuration["ConnectionStrings:CMDBConnString"];//"Data Source=itadmin;Initial Catalog=CMDB;Persist Security Info=True;User ID=sa;Password=AquaT1nta";
            string retJson = "{}";

            using (var conn = new SqlConnection(con))
            {
                using (var cmd = new SqlCommand("Select dbo.fn_Json_v2(@PersonId, @IsRoot)", conn))
                {
                    cmd.CommandTimeout = 30;

                    cmd.Parameters.AddWithValue("@PersonId", id);
                    cmd.Parameters.AddWithValue("@IsRoot", 1);

                    conn.Open();

                    SqlDataReader reader = cmd.ExecuteReader();

                    StringBuilder sb = new StringBuilder();
                    while (reader.Read()) sb.Append(reader.GetSqlString(0).Value);

                    string getValue = sb.ToString();
                    if (getValue != null)
                    {
                        retJson = getValue.ToString();
                    }

                    conn.Close();
                    return retJson;
                }
            }


        }

        // POST api/<CMDB>
        [HttpPost]
        public void Post([FromBody] string value)
        {
        }

        // PUT api/<CMDB>/5
        [HttpPut("{id}")]
        public void Put(int id, [FromBody] string value)
        {
        }

        // DELETE api/<CMDB>/5
        [HttpDelete("{id}")]
        public void Delete(int id)
        {
        }
    }
}
