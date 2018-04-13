using System.Collections;
using System.Collections.Generic;

namespace Git.Automation
{
    public sealed class SendBranchResult : IEnumerable
    {
        public SendBranchResult()
        {
            MergeResult = new List<LibGit2Sharp.MergeResult>();
            PushResult = new List<Automation.PushResult>();
        }

        public LibGit2Sharp.MergeResult LastMergeResult { get { return MergeResult[MergeResult.Count - 1]; } }

        public PushResult LastPushResult { get { return PushResult[PushResult.Count - 1]; } }

        public List<LibGit2Sharp.MergeResult> MergeResult { get; private set; }

        public List<PushResult> PushResult { get; private set; }

        public IEnumerator GetEnumerator()
        {

            var maxIdx = MergeResult.Count;
            if (PushResult.Count > maxIdx)
                maxIdx = PushResult.Count;

            var results = new ArrayList( MergeResult.Count + PushResult.Count );

            for( int idx = 0; idx < maxIdx; ++idx )
            {
                if( MergeResult.Count < idx )
                {
                    results.Add(MergeResult[idx]);
                }

                if( PushResult.Count < idx )
                {
                    results.Add(PushResult[idx]);
                }
            }

            return results.GetEnumerator();
        }
    }
}
