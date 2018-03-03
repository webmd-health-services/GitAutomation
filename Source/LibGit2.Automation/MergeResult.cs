using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using LibGit2Sharp;

namespace LibGit2.Automation
{
    public sealed class MergeResult
    {
        public MergeResult(LibGit2Sharp.MergeResult result)
        {
            if( result.Commit != null )
            {
                Commit = new CommitInfo(result.Commit);
            }

            Status = result.Status;

        }

        public MergeStatus Status { get; private set; }

        public CommitInfo Commit { get; private set; }
    }
}
