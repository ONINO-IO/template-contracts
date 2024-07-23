Short Description
The BasicDataValidator smart contract is designed to manage data validation using a system of owner and auditor roles. It allows the storage and validation of data points, represented by SHA256 hashes, along with their timestamps.

Use Cases
This smart contract can be used in scenarios where data integrity needs to be maintained and verified over time. It is particularly useful in applications like document verification, supply chain management, and any other context where the authenticity and integrity of data need to be guaranteed and audited by authorized parties.

Functionality
The contract enables the owner to store data points, represented as SHA256 hashes, with associated timestamps. It maintains a mapping of these data points, each identified by a unique ID. Auditors, assigned by the owner, can validate the integrity of these data points by comparing provided hashes against the stored hashes. The contract also includes functionality for managing auditor roles and transferring ownership.