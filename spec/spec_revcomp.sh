Describe 'revcomp.sh'
  Include bin/revcomp.sh
  It 'makes DNA reverse complement: A<->T, G<->C'
    When call revcomp "AAAAAA"
    The output should equal 'TTTTTT'
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