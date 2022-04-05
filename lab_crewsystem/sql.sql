USE `crew`;

CREATE TABLE IF NOT EXISTS `crew_list` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(30) NOT NULL,
  `crew` varchar(30) NOT NULL,
  `money` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;

CREATE TABLE IF NOT EXISTS `storage` (
  `code` varchar(100) NOT NULL,
  `item` varchar(40) NOT NULL,
  `type` varchar(20) NOT NULL,
  `ammo` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `warehouses` (
  `identifier` varchar(100) NOT NULL,
  `label` varchar(50) NOT NULL,
  `code` varchar(100) NOT NULL,
  `x` float NOT NULL,
  `y` float NOT NULL,
  `z` float NOT NULL,
  `crew` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE `users` ADD COLUMN `crew` varchar(25) DEFAULT 'nocrew';
ALTER TABLE `users` ADD COLUMN `crew_grade` varchar(25) DEFAULT 'nocrew';