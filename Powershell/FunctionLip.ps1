Function ExtractNumbers ([string]$InStr, [int]$Substart, [int]$subend, [string]$dateindigit){
    
   if ($dateindigit -eq 'Y') {

   if ($subend -eq 0 ) {
      $Out = $InStr.Substring($Substart) -replace ("[^\d{6,}]")
   }

   if ($subend -gt 0 ) {
      $Out = $InStr.Substring($Substart,$subend) -replace ("[^\d{6,}]")
   }

   try{return [int]$Out}
       catch{}
   try{return [uint64]$Out}
       catch{return 0}


   }else {
   
   
  if ($subend -eq 0 ) {
      $Out = $InStr.Substring($Substart)
   }

  if ($subend -gt 0 ) {
      $Out = $InStr.Substring($Substart,$subend)
   }

   try{return [String]$Out}
       catch{}
   try{return [String]$Out}
       catch{return 0}
   
   
   }    
   }



