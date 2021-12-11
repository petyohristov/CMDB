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



// For more information on enabling Web API for empty projects, visit https://go.microsoft.com/fwlink/?LinkID=397860

namespace CMDB_API_services.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class GetSubCIs : ControllerBase
    {
        private readonly IConfiguration Configuration;

        public GetSubCIs(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        // GET: api/<GetSubCIs>
        [HttpGet]
        public IEnumerable<string> Get()
        {
            return new string[] { "value1", "value2" };
        }

        // GET api/<GetSubCIs>/5
        [HttpGet("{id}")]
        public string Get(string id)
        {

            string con = Configuration["ConnectionStrings:CMDBConnString"];
            string retJson = "{}";

            using (var conn = new SqlConnection(con))
            {
                using (var cmd = new SqlCommand("Select dbo.GetMainSubCI(@CI)", conn))
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


        // POST api/<GetSubCIs>
        [HttpPost]
        public void Post([FromBody] string value)
        {
        }

        // PUT api/<GetSubCIs>/5
        [HttpPut("{id}")]
        public void Put(int id, [FromBody] string value)
        {
        }

        // DELETE api/<GetSubCIs>/5
        [HttpDelete("{id}")]
        public void Delete(int id)
        {
        }
    }
}
