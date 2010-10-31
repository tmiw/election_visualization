<?php
    include 'config.inc';
    $db_conn = mysql_pconnect($db_host, $db_user, $db_password) or die(mysql_error());
    mysql_select_db($db_database) or die(mysql_error());
?>
<html>
<head>
  <title>Election 2010: Live Results</title>
  <meta http-equiv="refresh" content="60" />
  <style type="text/css">
      body { font-family: Georgia, serif; }
      .result_bar { width: 100%; }
      .result_bar .dem_result { color: blue; float: left; }
      .result_bar .gop_result { color: red; }
      .result_bar .ind_result { color: green; float: left; }
      .result_bar .unknown_result { color: gray; float: left; }
      .result_text { width: 100%; }
      .result_text .dem_result { float: left; }
      .result_text .ind_result { float: left; }
      .result_text .unknown_result { float: left; }
      .result_text .gop_result {  }
  </style>
</head>
<body>
<?php
    if (array_key_exists('race_type', $_GET))
    {
        $query = mysql_query("SELECT * FROM election_result ORDER BY last_update DESC, race_name ASC") or die(mysql_error());
    }
    else
    {
        $query = mysql_query("SELECT * FROM election_result WHERE race_type='" . $_GET['race_type'] . "' ORDER BY race_name ASC") or die(mysql_error());
    }
?>
<?php 
    if (mysql_num_rows($query) == 0)
    {
        ?>
No results yet.
        <?php
    }
    else
    {
        ?>
<table width='100%'>
    <tr>
        <th>Name</th>
        <th>Result</th>
        <th>Last Update</th>
    </tr>
    <?php
        while($row = mysql_fetch_assoc($query))
        {
            $unknown_percent = (100 -  $row['democrat_percent'] - $row['ind_percent'] - $row['gop_percent']);
            ?>
            <tr>
                <td><?= $row['race_name'] ?></td>
                <td>
                    <div class='result_bar'>
                        <div class='dem_result' width='<?= $row['democrat_percent'] ?>%'>&nbsp;</div>
                        <div class='ind_result' width='<?= $row['ind_percent'] ?>%'>&nbsp;</div>
                        <div class='unknown_result' width='<?= $unknown_percent ?>%'>&nbsp;</div>
                        <div class='gop_result' width='<?= $row['gop_percent'] ?>%'>&nbsp;</div>
                    </div>
                    <div class='result_text'>
                        <div class='dem_result' width='<?= $row['democrat_percent'] ?>%'><?= $row['democrat_percent'] ?></div>
                        <div class='ind_result' width='<?= $row['ind_percent'] ?>%'><?= $row['democrat_percent'] ?></div>
                        <div class='unknown_result' width='<?= $unknown_percent ?>%'><?= $row['democrat_percent'] ?></div>
                        <div class='gop_result' width='<?= $row['gop_percent'] ?>%'><?= $row['democrat_percent'] ?></div>
                    </div>
                </td>
                <td>
                    <?= $row['last_update'] ?>
                </td>
            </tr>
            <?php
        }
    }
?>
</body>
</html>