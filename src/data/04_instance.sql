-- Example data for instance (20 instances)
-- Uses realistic CPU models
-- Bumped partition numbers to reflect production customer-facing file servers


TRUNCATE TABLE service.instance RESTART IDENTITY CASCADE;

INSERT INTO service.instance (
    id,
    region,
    system_version,
    cpu,
    max_ram_gb,
    system_partition_gb,
    files_partition_tb,
    max_upload,
    max_download
) VALUES
    ('service.instance-001', 'eu-central-1', 'v2.4.1', 'Intel Xeon E-2288G', 64, 512, 25, 500, 1000),
    ('service.instance-002', 'eu-west-1', 'v2.4.1', 'AMD EPYC 7551', 128, 750, 50, 500, 2000),
    ('service.instance-003', 'us-east-1', 'v2.3.8', 'Intel Xeon Gold 6248R', 256, 1024, 100, 1000, 4000),
    ('service.instance-004', 'eu-north-1', 'v2.4.1', 'AMD Ryzen 9 5950X', 32, 400, 20, 250, 1000),
    ('service.instance-005', 'ap-southeast-1', 'v2.4.0', 'Intel Core i9-10900K', 64, 600, 30, 500, 2000),
    ('service.instance-006', 'us-west-2', 'v2.3.8', 'AMD EPYC 7702', 128, 800, 60, 1000, 4000),
    ('service.instance-007', 'eu-central-1', 'v2.4.1', 'Intel Xeon E-2388G', 32, 350, 15, 250, 1000),
    ('service.instance-008', 'eu-west-2', 'v2.4.1', 'AMD EPYC 7543', 128, 900, 75, 1000, 4000),
    ('service.instance-009', 'us-east-2', 'v2.3.9', 'Intel Xeon Platinum 8380', 256, 1500, 150, 1000, 8000),
    ('service.instance-010', 'ap-northeast-1', 'v2.4.0', 'AMD Ryzen 9 5900X', 64, 500, 25, 500, 2000),
    ('service.instance-011', 'eu-central-1', 'v2.4.2', 'Intel Xeon Gold 6338', 128, 750, 50, 1000, 4000),
    ('service.instance-012', 'eu-west-3', 'v2.4.1', 'AMD EPYC 7452', 128, 1000, 80, 1000, 4000),
    ('service.instance-013', 'us-west-1', 'v2.3.8', 'Intel Xeon E-2276G', 32, 400, 18, 250, 1000),
    ('service.instance-014', 'ap-south-1', 'v2.4.0', 'AMD Ryzen 7 5800X', 64, 600, 32, 500, 2000),
    ('service.instance-015', 'eu-north-1', 'v2.4.2', 'Intel Xeon Silver 4314', 128, 800, 55, 500, 2000),
    ('service.instance-016', 'us-east-1', 'v2.4.2', 'AMD EPYC 7662', 256, 1200, 120, 1000, 8000),
    ('service.instance-017', 'eu-central-1', 'v2.4.2', 'Intel Xeon Gold 6258R', 256, 1500, 150, 1000, 8000),
    ('service.instance-018', 'eu-west-1', 'v2.4.1', 'AMD EPYC 7402P', 128, 950, 70, 1000, 4000),
    ('service.instance-019', 'ap-southeast-2', 'v2.4.0', 'Intel Core i7-11700K', 32, 350, 16, 250, 1000),
    ('service.instance-020', 'us-west-2', 'v2.4.2', 'AMD EPYC 7542', 256, 1300, 130, 1000, 8000)
;