# Schemas

## ER Diagram

```mermaid
erDiagram
    %% Accounts DB
    Accounts {
        ID int PK
        Vorname string
        Nachname string
        Email string
        Telefon string
        Land string
        Stadt string
        PLZ string
        Straße string
        Hausnummer string
        Hausnummrezusatz string
        TrialGenutzt bool
        AGBVersion string
    }
    
    Password {
        AccountID int PK
        Hash bytes
        Salt bytes
    }
    
    Abo {
        ID int PK
        AccountID int FK
        Typ string
        Start datetime
        Ende datetime
        Auto-Verlängerung bool
        PaymentDetailsID int FK
    }
    
    PaymentDetails {
        ID int PK
        Methode string
        Betrag decimal
        Währung string
        Status string
        Transaktionsreferenz string
    }
    
    PaymentLogRow {
        TimeStamp datetime PK
        AboID int FK,PK
        PaymentDetailsID int FK
        Betrag decimal
        War-Auto-Verlängerung bool
        BestätigungsEmailID string
    }
    
    %% Service DB
    Instance {
        ID int PK
    }
    
    File {
        ID int PK
        InstanceID string
        OwnerAccountID int FK
        FileName string
        FilePath string
        Size int
        Created datetime
        Modified datetime
        LastDownload datetime
        CreatedBy string
        ModifiedBy string
    }
    
    IPPermission {
        ID int PK
        TargetID int FK
        Read string
        Write string
        Create string
        Delete string
        IPv4 IPv4
        MaskV4 int
        IPv6 IPv6
        MaskV6 int
    }
    
    AccountPermission {
        ID int PK
        TargetID int FK
        AccountID int FK
        Read bool
        Write bool
        Create bool
        Delete bool
    }
    
    FileGroup {
        RelationID int PK
        FileID int FK
        GroupName string
    }

    %% Logs DB
    AccessLogRow {
        TimeStamp int PK
        AccountID int FK
        IPv4 string
        IPv6 string
        FileID int FK,PK
        Operation string
    }

    PerformanceLogRow {
        TimeStamp datetime PK
        InstanceID string PK
        Region string
        Status string
        SystemVersion string
        CPUPercent float
        RamGB int
        SystemStorageGB int
        FileStorageTB float
        NetworkUpload float
        NetworkDownload float
        CPUTemp float
        DiskTemp float
        EnvironmentTemp float
    }

    %% Relationships
    %% Accounts DB
    Accounts ||--|| Password : authenticates
    Accounts ||--o| Abo : has-one
    Abo ||--o{ PaymentLogRow : logs
    Abo }o--|| PaymentDetails : uses
    PaymentDetails |o--o{ PaymentLogRow : logs
    %% Service DB
    Instance ||--o{ File : stored-on
    Accounts ||--o{ File : owns
    File }o--o{ FileGroup : belongs-to
    Accounts ||--o{ AccountPermission : has-permission
    Accounts ||--o{ AccountPermission : for-storage
    AccountPermission |o--o{ FileGroup : for-files
    IPPermission |o--o{ FileGroup : for-files
    Accounts ||--o{ IPPermission : for-storage
    %% Logs DB
    Instance ||--o{ PerformanceLogRow : has-logs
    Accounts ||--o{ AccessLogRow : by-user
    File ||--o{ AccessLogRow : logs-access
```

## Accounts DB

### PII zu Nutzer ID

Accounts(ID, Vorname, Nachname, Email, Telefon, Land, Stadt, PLZ, Straße, Hausnummer, Hausnummrezusatz, TrialGenutzt, AGBVersion)

### Password / Auth

Password(AccountID, Hash, Salt)

### Abos zu Nutzer ID

Abo(ID, AccountID, Typ, Start, Ende, Auto-Verlängerung, PaymentDetailsID)

### Payment Details

PaymentDetails(ID, Methode, Betrag, Währung, Status, Transaktionsreferenz)

### Payment Logs

PaymentLogRow(TimeStamp, AboID, PaymentDetailsID, Betrag, War-Auto-Verlängerung, BestätigungsEmailID)

## Service DB

Instance(ID)

### Datei zu Nutzer ID

File(ID, InstanceID, OwnerAccountID, FileName, FilePath, Size, Created, Modified, LastDownload, CreatedBy, ModifiedBy)

### Datei Berechtigungen

IPPermission(ID, TargetID, Read(Grant/Deny), Write(Grant/Deny), Create(Grant/Deny), Delete(Grant/Deny), IPV4, MaskV4, IpV6, MaskV6, FileGroup)

AccountPermission(ID, AccountID, TargetID, Read(True,False), Write(True,False), Create(True,False), Delete(True,False), FileGroup)

FileGroup(RelationID, GroupName, FileID)

## Logs DB

### File Access Logs

AccessLogRow(TimeStamp, AccountID, IPv4, IPv6, FileID, Operation)

### Performance Logs

PerformanceLogRow(TimeStamp, InstanceID, Region, Status, SystemVersion, CPU%, RamGB, SystemStorageGB, FileStorageTB, NetworkUpload, NetworkDownload, CPUTemp, DiskTemp, EnvironmentTemp)