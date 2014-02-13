SET NAMES utf8;

DROP TABLE IF EXISTS `chat`;
CREATE TABLE `chat` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `sender` char(40) NOT NULL,
  `acceptor` char(40) NOT NULL,
  `message` varchar(65535) NOT NULL,
  `status` tinyint(4) NOT NULL DEFAULT '1' COMMENT '1 for unread, 2 for read',
  `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `sender` (`sender`, `acceptor`),
  KEY `acceptor` (`acceptor`, `sender`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
