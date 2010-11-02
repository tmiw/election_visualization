<?php

    function interval_since_now($tm)
    {
        $dt = date_create($tm);
        $datediff = $dt->diff(date_create(), true);
        
        if ($datediff->y > 0)
        {
            $format_string = "%y years";
        }
        else if ($datediff->m > 0)
        {
            $format_string = "%m months";
        }
        else if ($datediff->d > 0)
        {
            $format_string = "%d days";
        }
        else if ($datediff->h > 0)
        {
            $format_string = "%h hours";
        }
        else if ($datediff->i > 0)
        {
            $format_string = "%i minutes";
        }
        else
        {
            $format_string = "%s seconds";
        }
        $diff_formatted = $datediff->format($format_string);
        
        if (preg_match("/^1 /", $diff_formatted))
        {
            $diff_formatted = preg_replace("/s$/", "", $diff_formatted);
        }
        
        return $diff_formatted;
    }
    
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
      .navigation { position: fixed; top: 0px; right: 0px; float: right; border: 1px solid black; width: 300px; text-align: right; }
      .content { padding-right: 300px; }
      
      .result_bar { }
      .result_bar .dem_result { background-color: blue; float: left; }
      .result_bar .gop_result { background-color: red; float: left; }
      .result_bar .ind_result { background-color: green; float: left; }
      .result_bar .unknown_result { background-color: gray; }
      .result_text { }
      .result_text .dem_result { float: left; text-align: left; }
      .result_text .ind_result { float: left; text-align: center; }
      .result_text .unknown_result { text-align: right; }
      .result_text .gop_result{ float: left; text-align: center; }
  </style>
</head>
<body>
<?php
    if (!array_key_exists('race_type', $_GET))
    {
        $query = mysql_query("SELECT type.race_type, result.race_name, result.democrat_percent, result.gop_percent, result.ind_percent, result.last_update FROM election_result AS result INNER JOIN election_race_type AS type ON type.id=result.race_type ORDER BY last_update DESC, race_type ASC, race_name ASC") or die(mysql_error());
    }
    else
    {
        $query = mysql_query("SELECT type.race_type, result.race_name, result.democrat_percent, result.gop_percent, result.ind_percent, result.last_update FROM election_result AS result INNER JOIN election_race_type AS type ON type.id=result.race_type WHERE result.race_type='" . $_GET['race_type'] . "' ORDER BY race_name ASC") or die(mysql_error());
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
<div class="content">
<table>
    <tr>
        <th>Type</th>
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
                <td><?= $row['race_type'] ?></td>
                <td><?= $row['race_name'] ?></td>
                <td>
                    <div class='result_bar'>
                        <div class='dem_result' style="width: <?= $row['democrat_percent'] * 3 ?>px">&nbsp;</div>
                        <div class='ind_result' style="width: <?= $row['ind_percent'] * 3 ?>px">&nbsp;</div>
                        <div class='gop_result' style="width: <?= $row['gop_percent'] * 3?>px">&nbsp;</div>
                        <div class='unknown_result' style="width: <?= $unknown_percent * 3 ?>px">&nbsp;</div>
                    </div>
                    <div class='result_text'>
                        <div class='dem_result' style="width: <?= $row['democrat_percent']*3 ?>px"><?= $row['democrat_percent'] ?></div>
                        <div class='ind_result' style="width: <?= $row['ind_percent']*3 ?>px"><?= $row['ind_percent'] ?></div>
                        <div class='gop_result' style="width: <?= $row['gop_percent']*3 ?>px"><?= $row['gop_percent'] ?></div>
                        <div class='unknown_result' style="width: <?= $unknown_percent * 3 ?>px"><?= $unknown_percent ?></div>
                    </div>
                </td>
                <td>
                    <?= interval_since_now($row['last_update']) ?> ago
                </td>
            </tr>
            <?php
        }
    }
?>
</div>
<div class="navigation">
    <a href="?">All Results</a><br />
    <?php
        $query = mysql_query("SELECT id, race_type FROM election_race_type ORDER BY race_type ASC");
        while($row = mysql_fetch_assoc($query))
        {
            ?><a href="?race_type=<?= $row['id'] ?>"><?= $row['race_type'] ?></a><br /><?php
        }
    ?><br />
    <?php
        $query = mysql_query("(select 'dem' as party, count(id) as won from election_result where gop_percent < democrat_percent) union (select 'gop' as party, count(id) as won from election_result where democrat_percent < gop_percent)");
        $num_wins = array();
        while($row = mysql_fetch_assoc($query))
        {
            $num_wins[$row['party']] = $row['won']; 
        }
    ?>
    <b>Democrat/Yes wins:</b> <?= $num_wins['dem'] ?><br />
    <b>GOP/No wins:</b> <?= $num_wins['gop'] ?> 
</div>
</body>
</html>
