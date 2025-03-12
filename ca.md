![image-20250306153906379](./ca.assets/image-20250306153906379.png)

![image-20250306154147261](./ca.assets/image-20250306154147261.png)

![image-20250312142847612](./ca.assets/image-20250312142847612.png)

![image-20250306154158318](./ca.assets/image-20250306154158318.png)

![image-20250306154621471](./ca.assets/image-20250306154621471.png)

![image-20250306154559520](./ca.assets/image-20250306154559520.png)

![image-20250306155333225](./ca.assets/image-20250306155333225.png)

![image-20250306160511643](./ca.assets/image-20250306160511643.png)

![image-20250306162932450](./ca.assets/image-20250306162932450.png) 





![image-20250306165046108](./ca.assets/image-20250306165046108.png)

![image-20250306214227323](./ca.assets/image-20250306214227323.png)

![image-20250306220151942](./ca.assets/image-20250306220151942.png)

![image-20250306220242799](./ca.assets/image-20250306220242799.png)

![image-20250312150403929](./ca.assets/image-20250312150403929.png)

![image-20250312151146646](./ca.assets/image-20250312151146646.png)

![image-20250310181921220](./ca.assets/image-20250310181921220.png)

![image-20250310181929604](./ca.assets/image-20250310181929604.png)





![image-20250310182432485](./ca.assets/image-20250310182432485.png)

![image-20250310183316014](./ca.assets/image-20250310183316014.png)

![image-20250310203259743](./ca.assets/image-20250310203259743.png)

![image-20250312152231317](./ca.assets/image-20250312152231317.png)![image-20250312152240105](./ca.assets/image-20250312152240105.png)

![image-20250310183508389](./ca.assets/image-20250310183508389.png)

![image-20250310203331685](./ca.assets/image-20250310203331685.png)

```mermaid
sequenceDiagram
    participant U as User
    participant S as Server
    participant DB as Database

    Note over U: Three concurrent like requests are sent
    U->>S: Like Request #1
    U->>S: Like Request #2
    U->>S: Like Request #3

		par Process Request 1
        S->>DB: READ likedBy field
        DB-->>S: likedBy is []  % Concurrent read, before 2&3's update
        S->>DB: UPDATE likedBy = [User1], INCR like
        DB-->>S: ACK (like count +1)
    and Process Request 2
        S->>DB: READ likedBy field
        DB-->>S: likedBy is []  % Concurrent read, before 1&3's update
        S->>DB: UPDATE likedBy = [User1], INCR like
        DB-->>S: ACK (like count +1)
    and Process Request 3
        S->>DB: READ likedBy field
        DB-->>S: likedBy is []  % Concurrent read, before 1&2's update
        S->>DB: UPDATE likedBy = [User1], INCR like
        DB-->>S: ACK (like count +1)
    end

    Note over DB: Final result: like count increased 3 times, but likedBy remains as [User1]
```

