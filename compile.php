<?php
if ($argc == 2) {
  $CURRDIR=$argv[1];
} else {
  $CURRDIR=$_SERVER['PWD'];
}
$DATADIR="$CURRDIR/package/contents/code/db";
$WORKDIR="$CURRDIR/tmp";

function read($csv,$sep){
    $file = fopen($csv, 'r');
    while (!feof($file) ) {
        $line[] = fgetcsv($file, 1024, $sep);
    }
    fclose($file);
    return $line;
}
$timezoneData=read("$WORKDIR/timezone.csv",",");
$zoneData=read("$WORKDIR/zone.csv",",");

$databaseObjects=array();

$fromDate=mktime(0,0,0,1,1,2021);
$toDate=mktime(0,0,0,31,12,2032);

$f=0;
foreach($zoneData as $line)
{
//   echo ".";
  if ($line != "") {
    if (sizeof($line) == 3) {
      $objGeneral=array();
      $objGeneral["displayName"]=$line[2];
      $recordNumber=$line[0];
      $objGeneral["id"]=$recordNumber - 1;

      unset($dstData);
      $dstData=Array();
      unset($dstLine);

      $dstCount=0;
      do {
        $tzdata=$timezoneData[$f];
        $timeStamp=intval($tzdata[2]);
        if (($timeStamp > $fromDate) && ($timeStamp < $toDate)) {
          if ($tzdata[4] == 1) {
            unset($dstLine);
            $dstLine["DSTStart"]=$timeStamp;
            if (! array_key_exists("DSTOffset",$objGeneral)) {
              $objGeneral["DSTOffset"]=$tzdata[3];
            }
            if (! array_key_exists("DSTName",$objGeneral)) {
              $objGeneral["DSTName"]=$tzdata[1];
            }

          } else {
            if (isset($dstLine["DSTStart"]) && ($dstLine["DSTStart"] < $timeStamp)) {
              $dstLine["DSTEnd"]=$timeStamp;
            }
            if (! array_key_exists("Offset",$objGeneral)) {
              $objGeneral["Offset"]=$tzdata[3];
            }
            if (! array_key_exists("TZName",$objGeneral)) {
              $objGeneral["TZName"]=$tzdata[1];
            }
          }
          if (isset($dstLine) && sizeOf($dstLine)==2) {
            array_push($dstData,$dstLine);
          }

        }
        $f++;
        if (!($timezoneData[$f]))
          break;
      } while ($timezoneData[$f][0]==$recordNumber);

//       if ($recordNumber==360) { var_dump($tzdata);}

      if (! array_key_exists("TZName",$objGeneral)) {
        $objGeneral["TZName"]=$tzdata[1];
      }
      if (! array_key_exists("Offset",$objGeneral)) {
        $objGeneral["Offset"]=$tzdata[3];
      }
//       echo $line[0]."\t\t\t".$line[2]."\t\t\t".$tzdata[3]."\n";
      if (sizeOf($dstData) > 0) {
        $objGeneral["DSTData"]=$dstData;
      unset($dstData);
      }
      array_push($databaseObjects,$objGeneral);
      unset($dstData);
    }
  }
}
echo "\n";
file_put_contents("$DATADIR/timezoneData.js", "const TZData =".json_encode($databaseObjects));
?>
