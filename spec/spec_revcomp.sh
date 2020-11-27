#!/bin/sh

Describe 'revcomp.sh'
  Include bin/revcomp.sh
  It 'makes DNA reverse order'
    When call reverse_dna "CCACGTTTTT"
    The output should equal 'TTTTTGCACC'
  End
End

Describe 'revcomp.sh'
  Include bin/revcomp.sh
  It 'makes DNA complement: A->T, T->A, C->G, G->C'
    When call complement_dna "CCACGTTTTT"
    The output should equal 'GGTGCAAAAA'
  End
End

Describe 'revcomp.sh'
  Include bin/revcomp.sh
  It 'makes DNA reverse complement'
    When call revcomp_dna "ATGCATGC"
    The output should equal 'GCATGCAT'
  End
End