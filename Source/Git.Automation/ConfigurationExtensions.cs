// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//  
//    http://www.apache.org/licenses/LICENSE-2.0
//   
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

using LibGit2Sharp;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Git.Automation
{
    public static class ConfigurationExtensions
    {
        public static ConfigurationEntry<string> GetString(this Configuration configuration, string[] keyParts)
        {
            return configuration.Get<string>(keyParts);

        }

        public static ConfigurationEntry<string> GetString(this Configuration configuration, string firstKeyPart, string secondKeyPart, string thirdKeyPart)
        {
            return configuration.Get<string>(firstKeyPart, secondKeyPart, thirdKeyPart);
        }

        public static ConfigurationEntry<string> GetString(this Configuration configuration, string key)
        {
            return configuration.Get<string>(key);
        }

        public static ConfigurationEntry<string> GetString(this Configuration configuration, string key, ConfigurationLevel level)
        {
            return configuration.Get<string>(key, level);
        }
    }
}
