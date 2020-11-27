Describe 'revcomp.sh'
  Include bin/minimap_scoring.sh
  It 'makes DNA reverse: A->T'
    When call revcomp "AAAA"
    The output should equal 'TTTT'
  End
End

Describe 'revcomp.sh'
  Include bin/revcomp.sh
  It 'makes DNA reverse complement'
    When call revcomp "AAAAAT"
    The output should equal 'ATTTTT'
  End
End

Describe 'revcomp.sh'
  Include bin/revcomp.sh
  It 'makes DNA reverse complement'
    When call revcomp "ATGCATGC"
    The output should equal 'GCATGCAT'
  End
End