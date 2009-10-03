<?php

$s = file_get_contents('%@');

// trim each line separately
$s_arr = explode("\n", $s);
$s_arr_trim = array();
foreach ($s_arr as $key => $value)
{
	array_push($s_arr_trim, trim($value));
}
$s = implode("\n", $s_arr_trim);

// replace br's with newlines, li's with asterisks
$s = str_replace('<br>', "\n", $s);
$s = str_replace('<br/>', "\n", $s);
$s = str_replace('<br />', "\n", $s);
$s = str_replace('<li>', '  * ', $s);

// strip tags, translate html entities
$s = html_entity_decode(strip_tags($s), ENT_QUOTES, 'UTF-8');

// word-wrap each list item line separately with
// nicer indentation
$s_arr = explode("\n", $s);
$s_arr_trim = array();
foreach ($s_arr as $key => $value)
{
	$newvalue = $value;
	if (strpos($newvalue, '  * ') == 0)
	{
		$newvalue = wordwrap($newvalue, 75, "\n    ");
	}
	array_push($s_arr_trim, $newvalue);
}
$s = implode("\n", $s_arr_trim);

// word-wrap the whole thing
echo wordwrap($s, 80);

?>
