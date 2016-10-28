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

using System;
using System.Diagnostics;
using System.IO;
using System.Text;
using LibGit2Sharp;
using NUnit.Framework;

namespace LibGit2.Automation
{
	public class SshExeTransportStream : SmartSubtransportStream, IDisposable
	{
		private Process _process;
		private bool _started;

		private void splitHostPath(string url, out string host, out string user, out string path, out string port)
		{
			try
			{
				var parsedUrl = new Uri(url);
				host = parsedUrl.Host;
				user = parsedUrl.UserInfo;
				port = parsedUrl.IsDefaultPort ? null : parsedUrl.Port.ToString();
				path = parsedUrl.LocalPath.Substring(1);
			}
			catch (UriFormatException)
			{
				throw new NotImplementedException();
			}
		}

		public SshExeTransportStream(SshExeTransport parent, string url, string procName)
			: base(parent)
		{
			Trace.WriteLine(procName);
			// this probably needs more escaping so we pass single quotes
			// to the upload-pack/receive-pack process itself
			string host, user, path, port;
			splitHostPath(url, out host, out user, out path, out port);

			var args = String.Format("{0}@{1} \"{2} '{3}'\"", user, host, procName, path);
			if (port != null)
			{
				args = String.Format("-p {0} {1}", port, args);
			}
			Trace.WriteLine("args {0}", args);

			_process = new Process
			{
				StartInfo =
				{
					FileName = SshExeTransport.ExePath,
					Arguments = args,
					UseShellExecute = false,
					RedirectStandardError = true,
					RedirectStandardInput = true,
					RedirectStandardOutput = true
				}
			};
			_process.ErrorDataReceived += (sender, e) => Console.WriteLine("{0}", e.Data);
		}

		private void ThrowSshFailedException(int exitCode)
		{
			var buf = new byte[8*1024];
			_process.StandardError.BaseStream.Read(buf, 0, buf.Length);
			var errorOutput = string.Format("ssh process terminated unexpectedly with exit code {0}: {1}", exitCode,
				Encoding.UTF8.GetString(buf));
			throw new Exception(errorOutput);
		}

		private void AssertAlive()
		{
			if (!_started)
			{
				_process.Start();
				_started = true;
			}

			if (_process.HasExited)
			{
				ThrowSshFailedException(_process.ExitCode);
			}
		}

		private void Close()
		{
			try
			{
				if (_process == null)
					return;

				if (!_process.HasExited)
				{
					_process.Kill();
					throw new Exception("Closing SSH transport stream before ssh.exe has finished.");
				}

				var exitCode = _process.ExitCode;

				if (exitCode != 0)
				{
					ThrowSshFailedException(exitCode);
				}
			}
			finally
			{
				if (_process != null)
				{
					_process.Close();
					_process = null;
				}
			}
		}

		protected override void Free()
		{
			base.Free();
			Close();
		}

		public override int Write(Stream stream, long length)
		{
			AssertAlive();

			try
			{

				while (length > 0)
				{
					int toCopy = length > int.MaxValue ? int.MaxValue : (int) length;
					var buf = new byte[toCopy];
					stream.Read(buf, 0, toCopy);
					// Console.WriteLine(Encoding.UTF8.GetString(buf));
					_process.StandardInput.BaseStream.Write(buf, 0, toCopy);
					_process.StandardInput.BaseStream.Flush();
					length -= toCopy;
				}

				return 0;
			}
			catch (Exception ex)
			{
				Console.WriteLine(ex);
				throw;
			}
		}

		public override int Read(Stream stream, long length, out long readTotal)
		{
			AssertAlive();

			var read = 0;
			readTotal = 0;
			if (_process == null)
			{
				return 0;
			}

			try
			{
				var buf = new byte[Math.Min(length, 8*1024)];
				var stdOut = _process.StandardOutput;
				var baseStream = stdOut.BaseStream;
				read = baseStream.Read(buf, 0, buf.Length);
				//Console.WriteLine(Encoding.UTF8.GetString(buf));
				stream.Write(buf, 0, read);
				stream.Flush();

				readTotal = read;

			}
			catch (Exception ex)
			{
				Console.WriteLine(ex);
				throw;
			}

			// If we get EOF, let's make sure the process didn't just die on us
			if (read == 0)
			{
				AssertAlive();
			}

			return 0;
		}

		public void Dispose()
		{
			Free();
		}
	}
}

