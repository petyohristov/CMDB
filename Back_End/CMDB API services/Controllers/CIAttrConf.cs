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
    public class CIAttrConf : ControllerBase
    {
        private readonly IConfiguration Configuration;

        public CIAttrConf(IConfiguration configuration)
        {
            Configuration = configuration;
        }


        // GET: api/<CIAttrConf>
        [HttpGet]
        public string Get()
        {

            string con = Configuration["ConnectionStrings:CMDBConnString"];
            string retJson = "{}";

            using (var conn = new SqlConnection(con))
            {
                using (var cmd = new SqlCommand("SELECT CITYPE_ID as Attribute_ID, CITYPE_NAME as Name, 'true' as Active, 'true' as Mandatory, 'false' as Multiple, 'BaseCI' as [Type], " +
                            "CITYPE_DESCRIPTION as Info FROM CITYPE WHERE ( CITYPE_TYPE = 'MAIN' AND TENANT = 'CMDB' ) for json path", conn))
                {
                    cmd.CommandTimeout = 30;

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
                    return "{\"Root_ID\":\"0\", \"Attributes\":" + retJson + "}" ;
                }
            }


        }

        // GET api/<CIAttrConf>/5
        [HttpGet("{id}")]
        public string Get(string id)
        {
            string con = Configuration["ConnectionStrings:CMDBConnString"];
            string retJson = "{}";

            using (var conn = new SqlConnection(con))
            {
                using (var cmd = new SqlCommand("Select dbo.GetCIAttributes(@CI)", conn))
                {
                    cmd.CommandTimeout = 30;

                    cmd.Parameters.AddWithValue("@CI", id);

                    conn.Open();

                    string getValue = cmd.ExecuteScalar().ToString();
                    if (getValue != null)
                    {
                        retJson = getValue.ToString();
                    }
                    conn.Close();
                    return retJson;
                }
            }
        }       
        
        // GET api/<CIAttrConf>/5
        [HttpGet("EditMode/{id}")]
        public string CIConfig(string id)
        {
            //string con = Configuration["ConnectionStrings:CMDBConnString"];
            //string retJson = "{}";

            //using (var conn = new SqlConnection(con))
            //{
            //    using (var cmd = new SqlCommand("Select dbo.GetCIAttributes(@CI)", conn))
            //    {
            //        cmd.CommandTimeout = 30;

            //        cmd.Parameters.AddWithValue("@CI", id);

            //        conn.Open();

            //        string getValue = cmd.ExecuteScalar().ToString();
            //        if (getValue != null)
            //        {
            //            retJson = getValue.ToString();
            //        }
            //        conn.Close();
            //        return retJson;
            //    }
            //}
            return id;
        }

        // POST api/<CIAttrConf>
        [HttpPost]
        public void Post([FromBody] string value)
        {
        }

        // PUT api/<CIAttrConf>/5
        [HttpPut("{id}")]
        public void Put(int id, [FromBody] string value)
        {
        }

        // DELETE api/<CIAttrConf>/5
        [HttpDelete("{ciid}")]
        public void Delete(int ciid)
        {
        }
    }
}
