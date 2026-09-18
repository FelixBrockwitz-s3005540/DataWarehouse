-- Performance log generation for all service instances
-- Generates ~100,000 rows of realistic performance logs
-- Rules respected:
--   * logs come in at a fixed interval (1 minute)
--   * most instances are online most of the time (sticky status transitions)
--   * some instances were added later (random start times within the period)
--   * all 20 instances from @src/data/04_instance.sql are covered
--   * metric values are derived from the instance hardware (max_ram_gb, etc.)
--   * system storage is more or less constant (slow OS noise only)
--   * file storage is sticky/drifting (random walk with occasional cleanup drops)
--   * servers initiate offline and come online after a boot delay

DO $$
DECLARE
    v_start_time timestamp := CURRENT_TIMESTAMP - INTERVAL '4 days';
    v_end_time timestamp := CURRENT_TIMESTAMP;
    v_interval interval := INTERVAL '1 minute';
    v_rec RECORD;
    v_timestamp timestamp;
    v_status logs.instance_status;
    v_cpu_percent float;
    v_ram_gb float;
    v_system_storage_gb float;
    v_file_storage_tb float;
    v_file_storage_drift float;
    v_network_upload float;
    v_network_download float;
    v_cpu_temp float;
    v_disk_temp float;
    v_environment_temp float;
    v_rows int := 0;
BEGIN
    TRUNCATE TABLE logs.performance_log_row RESTART IDENTITY CASCADE;

    FOR v_rec IN
        SELECT id, max_ram_gb, system_partition_gb, files_partition_tb, max_upload, max_download
        FROM service.instance
    LOOP
        -- Simulate instance being added later (random start within the first half of the period)
        v_timestamp := v_start_time + (random() * ((v_end_time - v_start_time) / 2));

        -- Servers initiate offline and boot after a delay of up to ~2 hours
        v_status := 'offline';

        -- System storage: constant base fill level per instance (30-60% of partition)
        -- plus a tiny per-row noise; it does NOT react to status (disk persists)
        v_system_storage_gb := v_rec.system_partition_gb * (0.30 + random() * 0.30);

        -- File storage: sticky base fill level per instance (20-50% of partition)
        v_file_storage_tb := v_rec.files_partition_tb * (0.20 + random() * 0.30);

        WHILE v_timestamp <= v_end_time LOOP
            -- Sticky status transitions (bias toward staying online)
            CASE v_status
                WHEN 'offline' THEN
                    -- Boot delay: on average ~45 min until the server comes up
                    IF random() < 0.022 THEN
                        v_status := 'online';
                    END IF;
                WHEN 'online' THEN
                    IF random() < 0.001 THEN
                        v_status := (ARRAY['degraded','maintenance','offline'])[floor(random()*3+1)];
                    END IF;
                WHEN 'degraded' THEN
                    IF random() < 0.20 THEN
                        v_status := 'online';
                    ELSIF random() < 0.40 THEN
                        v_status := 'degraded';
                    ELSIF random() < 0.25 THEN
                        v_status := 'maintenance';
                    ELSE
                        v_status := 'offline';
                    END IF;
                WHEN 'maintenance' THEN
                    IF random() < 0.10 THEN
                        v_status := 'online';
                    ELSIF random() < 0.80 THEN
                        v_status := 'maintenance';
                    ELSE
                        v_status := 'offline';
                    END IF;
            END CASE;

            -- File storage drift: slow random walk, occasional cleanup drop
            -- (uploads grow it slightly, cleanup jobs shrink it in rare steps)
            v_file_storage_drift := (random() - 0.35) * v_rec.files_partition_tb * 0.0005;
            IF random() < 0.002 THEN
                -- rare cleanup / retention job frees a bigger chunk
                v_file_storage_drift := -v_file_storage_tb * (0.02 + random() * 0.05);
            END IF;
            v_file_storage_tb := GREATEST(
                0,
                LEAST(v_rec.files_partition_tb, v_file_storage_tb + v_file_storage_drift)
            );

            -- Generate metrics based on status and instance hardware
            CASE v_status
                WHEN 'online' THEN
                    v_cpu_percent := random() * 60;
                    v_ram_gb := random() * v_rec.max_ram_gb * 0.65;
                    v_network_upload := random() * v_rec.max_upload * 0.35;
                    v_network_download := random() * v_rec.max_download * 0.35;
                    v_cpu_temp := 35 + random() * 35;
                    v_disk_temp := 25 + random() * 30;
                    v_environment_temp := 15 + random() * 20;
                WHEN 'degraded' THEN
                    v_cpu_percent := 70 + random() * 30;
                    v_ram_gb := v_rec.max_ram_gb * (0.75 + random() * 0.25);
                    v_network_upload := v_rec.max_upload * (0.5 + random() * 0.5);
                    v_network_download := v_rec.max_download * (0.5 + random() * 0.5);
                    v_cpu_temp := 55 + random() * 30;
                    v_disk_temp := 35 + random() * 35;
                    v_environment_temp := 15 + random() * 20;
                WHEN 'maintenance' THEN
                    v_cpu_percent := random() * 15;
                    v_ram_gb := random() * v_rec.max_ram_gb * 0.1;
                    v_network_upload := 0;
                    v_network_download := 0;
                    v_cpu_temp := 30 + random() * 20;
                    v_disk_temp := 25 + random() * 30;
                    v_environment_temp := 15 + random() * 20;
                WHEN 'offline' THEN
                    v_cpu_percent := 0;
                    v_ram_gb := 0;
                    v_network_upload := 0;
                    v_network_download := 0;
                    v_cpu_temp := 0;
                    v_disk_temp := 0;
                    v_environment_temp := 0;
            END CASE;

            INSERT INTO logs.performance_log_row (
                timestamp, instance_id, status, cpu_percent, ram_gb, system_storage_gb,
                file_storage_tb, network_upload, network_download, cpu_temp, disk_temp, environment_temp
            ) VALUES (
                v_timestamp, v_rec.id, v_status, v_cpu_percent, v_ram_gb,
                -- system storage stays near its base level (constant + tiny noise)
                v_system_storage_gb * (0.998 + random() * 0.004),
                v_file_storage_tb,
                v_network_upload, v_network_download, v_cpu_temp, v_disk_temp, v_environment_temp
            );

            v_rows := v_rows + 1;
            v_timestamp := v_timestamp + v_interval;
        END LOOP;
    END LOOP;

    RAISE NOTICE 'Generated % performance log rows', v_rows;
END $$;