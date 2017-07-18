<?php

// phpinfo();

function unichr($u) {
    return mb_convert_encoding('&#' . intval($u) . ';', 'UTF-8', 'HTML-ENTITIES');
}

$chars = [];

for ($i = 0; $i <= 0xffff; $i++) {
    $char = unichr($i);
    $res = MessageFormatter::formatMessage("en_US", "{".$char."}", [$char => 42]) !== false;
    $isWhitespace = MessageFormatter::formatMessage("en_US", "{a".$char."}", ["a" => 42]) === "42";
    if (json_encode($char) === false && $res === false) {
        continue;
    }
    $chars[$char] = [
        "result" => $res,
        "isWhitespace" => $isWhitespace,
    ];
}

file_put_contents("testchars.json", json_encode($chars, JSON_PRETTY_PRINT));

var_dump(json_last_error_msg());
