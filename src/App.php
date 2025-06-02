<?php

namespace App;

use Monolog\Formatter\JsonFormatter;
use Monolog\Handler\StreamHandler;
use Monolog\Level;
use Monolog\Logger;

use function date;

class App
{
    private Logger $logger;

    public function __construct()
    {
        $streamHandler = new StreamHandler('php://stdout', Level::Info);
        $streamHandler->setFormatter(new JsonFormatter());

        $this->logger = new Logger('name');
        $this->logger->pushHandler($streamHandler);
    }

    public function run(): void
    {
        $this->logger->info('Current time: ' . date('Y-m-d H:i:s'));
        $this->logger->warning('Just some static text');
    }
}