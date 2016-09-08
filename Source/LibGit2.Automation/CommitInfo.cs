using System.Collections.Generic;
using System.Linq;
using LibGit2Sharp;

namespace LibGit2.Automation
{
	public sealed class CommitInfo
	{
		public CommitInfo(Commit commit)
		{
			Author = commit.Author;
			Committer = commit.Committer;
			Encoding = commit.Encoding;
			Id = commit.Id;
			Message = commit.Message;
			MessageShort = commit.MessageShort;
			Notes = new List<Note>(commit.Notes).ToArray();

			Parents = new ObjectId[commit.Parents.Count()];
			var idx = 0;
			foreach( var parent in commit.Parents)
			{
				Parents[idx] = parent.Id;
				++idx;
			}
		}

		public Signature Author { get; private set; }
		public Signature Committer { get; private set; }
		public string Encoding { get; private set; }
		public ObjectId Id { get; private set; }
		public string Message { get; private set; }
		public string MessageShort { get; private set; }
		public Note[] Notes { get; private set; }
		public ObjectId[] Parents { get; private set; }

		public string Sha
		{
			get { return Id.Sha; }
		}
	}
}
