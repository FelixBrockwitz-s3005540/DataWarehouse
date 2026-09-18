-- Example data generator for accounts_db.sql
-- Creates ~100 rows for each table in the accounts schema
-- Leaves logs_db.sql untouched (empty)

-- ============================================================
-- Clean up existing data in all accounts schema tables
-- ============================================================


-- Truncate all tables in the accounts schema (CASCADE handles FK dependencies)
TRUNCATE TABLE accounts.accounts      RESTART IDENTITY CASCADE;
TRUNCATE TABLE accounts.password      RESTART IDENTITY CASCADE;
TRUNCATE TABLE accounts.payment_details RESTART IDENTITY CASCADE;
TRUNCATE TABLE accounts.abo           RESTART IDENTITY CASCADE;
TRUNCATE TABLE accounts.payment_log_row RESTART IDENTITY CASCADE;

-- ============================================================
-- Table: accounts (~100 rows)
-- ============================================================

INSERT INTO accounts.accounts
    (user_name, first_name, last_name, email, phone, country, city, postal_code, street, house_number, house_number_suffix, trial_used, agb_version)
VALUES
    ('John Doe', 'John', 'Doe', 'john.doe@example.com', '+49 1710123456', 'DE', 'Berlin', '10115', 'Musternstrasse', '123', 'A', TRUE, '20240101'),
    ('Jane Smith', 'Jane', 'Smith', 'jane.smith@test.org', '+44 7700123457', 'UK', 'London', 'Portobello Road', 'SW1A 1AA', '9', 'B', FALSE, '20240102'),
    ('Michael Johnson', 'Michael', 'Johnson', 'michael.j@company.de', '+49 1720138890', 'DE', 'Munich', '80529', 'Leopoldstraße', '45', 'C', FALSE, '20240103'),
    ('Sarah Lee', 'Sarah', 'Lee', 'sarah.lee@mail.net', '+61 412345678', 'AU', 'Sydney', '2000', 'Harbour Road', '88', 'D', FALSE, '20240104'),
    ('David Kim', 'David', 'Kim', 'david.kim@tech.co.uk', '+81 90 12345678', 'JP', 'Tokyo', '10801', 'Shinjuku', '12', 'E', TRUE, '20240105'),
    ('Emma Wilson', 'Emma', 'Wilson', 'emma.wilson@domain.com', '+33 1 40 82 34 56', 'FR', 'Paris', '75001', 'Avenue des Champs-Élysées', '55', 'F', FALSE, '20240106'),
    ('Robert Martinez', 'Robert', 'Martinez', 'robert.m@empresa.es', '+34 600 123 456', 'ES', 'Madrid', '28013', 'Calle de Alcalá', '23', 'G', TRUE, '20240107'),
    ('Lisa Nguyen', 'Lisa', 'Nguyen', 'lisa.ng@startup.io', '+62 213456789', 'MY', 'Kuala Lumpur', '50400', 'Jalan Bukit Bintang', '99', 'H', TRUE, '20240108'),
    ('Thomas Baker', 'Thomas', 'Baker', 'thomas.b@firm.com', '+44 20 7946 0958', 'UK', 'Manchester', 'M1 1AB', 'Queen Street', '7', 'Z', FALSE, '20240109'),
    ('Aisha Patel', 'Aisha', 'Patel', 'aisha.p@india.in', '+91 22 5555 0199', 'IN', 'Mumbai', '400001', 'Khadi Road', '34', 'Y', TRUE, '20240110'),
    ('Omar Hassan', 'Omar', 'Hassan', 'omar.h@world.org', '+83 2 1234 5678', 'DK', 'Copenhagen', '1100', 'Nørreport', '5', 'Q', TRUE, '20240111'),
    ('Yuki Tanaka', 'Yuki', 'Tanaka', 'yuki.t@japan.co.jp', '+81 90 1234 5678', 'JP', 'Tokyo', '10801', 'Shinjuku', '12', 'E', TRUE, '20240112'),
    ('Carlos Mendez', 'Carlos', 'Mendez', 'carlos.m@latam.com', '+52 55 1111 2222', 'MX', 'Mexico City', '06600', 'Av. Reforma', '22', 'S', TRUE, '20240113'),
    ('Nina Petrov', 'Nina', 'Petrov', 'nin.a@ru.org', '+7 495 123 4567', 'RU', 'Moscow', '103000', 'Lenin Square', '9', 'T', FALSE, '20240114'),
    ('James O''Brien', 'James', 'O''Brien', 'j.o''brien@us.com', '+1 415 555 0199', 'US', 'San Francisco', '94105', 'Market St', '41', 'U', TRUE, '20240115'),
    ('Elena Rossi', 'Elena', 'Rossi', 'elena.r@italy.it', '+39 02 1234 5678', 'IT', 'Rome', '00100', 'Piazza Navona', '3', 'V', FALSE, '20240116'),
    ('Kenji Sato', 'Kenji', 'Sato', 'k.sato@japan.net', '+81 90 9876 5432', 'JP', 'Tokyo', '10801', 'Shinjuku', '12', 'E', FALSE, '20240117'),
    ('Maria Garcia', 'Maria', 'Garcia', 'm.garcia@spain.es', '+34 612 345 678', 'ES', 'Barcelona', '08001', 'Port Vell', '67', 'P', FALSE, '20240118'),
    ('Chris Anderson', 'Chris', 'Anderson', 'chris.a@usa.com', '+1 312 555 0987', 'US', 'New York', '10001', 'Broadway', '120', 'M', FALSE, '20240119'),
    ('Sofia Andersson', 'Sofia', 'Andersson', 'sofia.a@sweden.se', '+46 8 123 456 78', 'SE', 'Stockholm', '18122', 'King Gustafsplan', '8', 'L', TRUE, '20240120'),
    ('Victor Lopez', 'Victor', 'Lopez', 'v.lopez@mexico.com', '+52 55 2222 3333', 'MX', 'Guadalajara', '44000', 'Avenida Revolución', '15', 'N', FALSE, '20240121'),
    ('Hannah Chen', 'Hannah', 'Chen', 'h.chen@asia.com', '+86 21 123 4567', 'CN', 'Beijing', '100000', 'Tiananmen Square', '2', 'Z', TRUE, '20240122'),
    ('Luca Moretti', 'Luca', 'Moretti', 'l.moretti@italy.it', '+39 06 1234 5678', 'IT', 'Milan', '20121', 'Piazza del Duomo', '11', 'K', FALSE, '20240123'),
    ('Isabella Rossi', 'Isabella', 'Rossi', 'isabella.r@france.fr', '+33 1 234 567 890', 'FR', 'Paris', '75010', 'Champs-Élysées', '44', 'J', TRUE, '20240124'),
    ('Daniel Kowalski', 'Daniel', 'Kowalski', 'daniel.k@poland.pl', '+48 22 123 456 789', 'PL', 'Warsaw', '00100', 'Świętokrzyskie', '5', 'O', FALSE, '20240125'),
    ('Amira Johansson', 'Amira', 'Johansson', 'ami.ja@swe.net', '+46 8 7654 3210', 'SE', 'Gothenburg', '511 24', 'Strömkällan', '9', 'P', FALSE, '20240126'),
    ('Ravi Sharma', 'Ravi', 'Sharma', 'ravi.s@india.in', '+91 22 4455 6789', 'IN', 'Delhi', '110001', 'Connaught Place', '28', 'M', TRUE, '20240127'),
    ('Olivia Brown', 'Olivia', 'Brown', 'olivia.b@uk.com', '+44 20 7946 7809', 'UK', 'London', 'N1 9AB', 'St James''s Park', '33', 'S', FALSE, '20240128'),
    ('Pedro Silva', 'Pedro', 'Silva', 'pedro.s@portugal.pt', '+351 21 123 4567', 'PT', 'Lisbon', '1100-000', 'Alfama', '7', 'L', TRUE, '20240129'),
    ('Zara Khan', 'Zara', 'Khan', 'z.khan@pakistan.ak', '+92 51 123 4567', 'PK', 'Karachi', '50001', 'Gulberg F7', '12', 'N', FALSE, '20240130'),
    ('Liam O''Connor', 'Liam', 'O''Connor', 'liam.oc@ireland.ie', '+53 1 234 567 890', 'IE', 'Dublin', '90107', 'Dublin Castle', '19', 'Q', FALSE, '20240131'),
    ('Mei Lin', 'Mei', 'Lin', 'mei.lin@china.com', '+86 21 5999 8888', 'CN', 'Shanghai', '200000', 'Lujiazui', '3', 'Z', FALSE, '20240201'),
    ('Diego Rodriguez', 'Diego', 'Rodriguez', 'd.rodriguez@mexico.com', '+52 55 4444 9999', 'MX', 'Monterrey', '48000', 'Plaza de la Liberación', '25', 'R', TRUE, '20240202'),
    ('Sophie Martin', 'Sophie', 'Martin', 'sophie.m@france.fr', '+33 1 9876 5432', 'FR', 'Lyon', '69001', 'Presqu''Hôtel', '8', 'P', TRUE, '20240203'),
    ('Arjun Patel', 'Arjun', 'Patel', 'arp\.patel@india.in', '+91 22 7777 8888', 'IN', 'Bangalore', '560032', 'Whitefield', '14', 'M', TRUE, '20240204'),
    ('Clara Müller', 'Clara', 'Müller', 'clara.m@germany.de', '+49 151 123 4567', 'DE', 'Hamburg', '23013', 'Elbphilharmonie', '2', 'L', TRUE, '20240205'),
    ('Nathan Wright', 'Nathan', 'Wright', 'n.wright@usa.com', '+1 310 555 1212', 'US', 'San Francisco', '94105', 'Mission District', '38', 'S', FALSE, '20240206'),
    ('Yuki Tanaka2', 'Yuki', 'Tanaka', 'y.tanaka@japan.co.jp', '+81 90 5555 1234', 'JP', 'Tokyo', '100-0001', 'Otemachi', '15', 'K', TRUE, '20240207'),
    ('Carlos Diaz', 'Carlos', 'Diaz', 'c.diaz@spanish.org', '+34 93 123 4567', 'ES', 'Madrid', '28013', 'Calle de Atocha', '22', 'R', TRUE, '20240208'),
    ('Emily Chen', 'Emily', 'Chen', 'emily.c@asia.net', '+86 21 8888 9999', 'CN', 'Shanghai', '202000', 'Lujiazui', '6', 'Z', FALSE, '20240209'),
    ('Felix Weber', 'Felix', 'Weber', 'f.weber@german.com', '+49 170 123 4567', 'DE', 'Frankfurt', '70557', 'Mainstraße', '9', 'M', TRUE, '20240210'),
    ('Ana Torres', 'Ana', 'Torres', 'ana.t@portuguese.pt', '+351 21 222 3333', 'PT', 'Lisbon', '1100-010', 'Rua da Prata', '5', 'P', FALSE, '20240211'),
    ('Samir Ahmed', 'Samir', 'Ahmed', 'sam.ahmed@egypt.eg', '+202 1234 5678', 'EG', 'Cairo', '115000', 'Al-Markaz', '12', 'N', TRUE, '20240212'),
    ('Jessica Lee', 'Jessica', 'Lee', 'j.lee@australia.edu', '+61 2 9876 5432', 'AU', 'Sydney', '2000', 'CBD', '47', 'S', FALSE, '20240213'),
    ('Mohammed Ali', 'Mohammed', 'Ali', 'm.ali@pakistan.ak', '+92 51 1122 3344', 'PK', 'Karachi', '50004', 'Gulberg E-11', '18', 'L', TRUE, '20240214'),
    ('Isabel Garcia', 'Isabel', 'Garcia', 'isabel.g@spain.es', '+34 612 345 678', 'ES', 'Barcelona', '08001', 'Parc de la Ciutadella', '33', 'P', FALSE, '20240215'),
    ('Tomás Rivera', 'Tomás', 'Rivera', 't.rivera@mexico.com', '+52 55 6666 7777', 'MX', 'Guadalajara', '45000', 'Centro Histórico', '19', 'R', FALSE, '20240216'),
    ('Benjamin Kim', 'Benjamin', 'Kim', 'b.kim@korean.net', '+82 10 1234 5678', 'KR', 'Seoul', '03171', 'Gangnam Blvd', '55', 'D', TRUE, '20240217'),
    ('Olivia Taylor', 'Olivia', 'Taylor', 'o.taylor@uk.com', '+44 7800 123456', 'UK', 'Bristol', 'BS1 1AA', 'Park Street', '22', 'U', TRUE, '20240218'),
    ('Erik Svensson', 'Erik', 'Svensson', 'erik.s@se.com', '+46 8 123 456 78', 'SE', 'Gothenburg', '411 12', 'Södergatan', '14', 'F', FALSE, '20240219'),
    ('Sophie Dubois', 'Sophie', 'Dubois', 'sophie.d@france.fr', '+33 6 12 34 56 78', 'FR', 'Nice', '06000', 'Promenade des Anglais', '2', 'X', TRUE, '20240220'),
    ('Javier Morales', 'Javier', 'Morales', 'j.morales@mexico.com', '+52 55 555 6677', 'MX', 'Mexico City', '06800', 'Avenida Revolución', '18', 'P', FALSE, '20240221'),
    ('Benedict Ng', 'Benedict', 'Ng', 'b.ng@singapore.gov', '+65 2 1234 5678', 'SG', 'Singapore', '129000', 'Orchard Road', '88', 'Y', FALSE, '20240222'),
    ('Luca Bianchi', 'Luca', 'Bianchi', 'l.bianchi@italy.it', '+39 06 9876 5432', 'IT', 'Milan', '20121', 'Piazza del Duomo', '11', 'K', FALSE, '20240223'),
    ('Isabelle Moreau', 'Isabelle', 'Moreau', 'isabelle.m@france.fr', '+33 1 5678 9012', 'FR', 'Lyon', '69001', 'Presqu''Hôtel', '8', 'P', FALSE, '20240224'),
    ('Hans Mueller', 'Hans', 'Mueller', 'h.mueller@germany.de', '+49 89 1234567', 'DE', 'Munich', '80331', 'Theresienplatz', '5', 'M', TRUE, '20240224');