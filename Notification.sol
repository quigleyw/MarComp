// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Notification
 * @dev Logs non-compliance alerts for vessels, including relevant details
 *      such as flag state and port state. Administrators can set port states
 *      for different locations.
 */
contract Notification {
    /// @dev Describes a compliance notification, including vessel ID and location.
    struct ComplianceNotification {
        uint256 timestamp;
        string vesselId;
        string message;
        string flagState;
        string portState;
    }

    /// @notice A list of all non-compliance notifications.
    ComplianceNotification[] public notifications;

    /// @notice Mapping from location -> port state label (e.g., "US Port").
    mapping(string => string) public portStates;

    /// @notice Address of the contract administrator who can modify port states.
    address public admin;

    /// @dev Restricts functions to only the admin address.
    modifier onlyAdmin() {
        require(msg.sender == admin, "Not authorized");
        _;
    }

    /**
     * @dev Emitted when a non-compliance event is reported.
     * @param vesselId The vessel's identifier or IMO number.
     * @param message A short description of the non-compliance.
     * @param flagState The vessel's flag state.
     * @param portState The location's assigned port state.
     */
    event NonComplianceReported(
        string vesselId,
        string message,
        string flagState,
        string portState
    );

    /**
     * @dev Sets the deployer as the contract `admin`.
     */
    constructor() {
        admin = msg.sender;
    }

    /**
     * @notice Admin function to define or update a port state's label for a given location string.
     * @param location A string denoting a geographic region or port location.
     * @param portState A descriptor for that port's status or ownership.
     */
    function setPortState(string memory location, string memory portState)
        external
        onlyAdmin
    {
        portStates[location] = portState;
    }

    /**
     * @notice Retrieves the port state for a specified location.
     * @param location The string naming the location (could be lat-lon, city, etc.).
     * @return The port state's descriptor.
     */
    function getPortState(string memory location)
        external
        view
        returns (string memory)
    {
        return portStates[location];
    }

    /**
     * @notice Records a new non-compliance event with descriptive details.
     * @param vesselId The vessel's identifier or IMO number.
     * @param message Short description of the issue (e.g., "Exceeds 0.10% in ECA").
     * @param flagState The vessel's flag state from VesselRegistration.
     * @param portState The port state for the relevant location or region.
     */
    function reportNonCompliance(
        string memory vesselId,
        string memory message,
        string memory flagState,
        string memory portState
    ) external {
        notifications.push(
            ComplianceNotification(
                block.timestamp,
                vesselId,
                message,
                flagState,
                portState
            )
        );
        emit NonComplianceReported(vesselId, message, flagState, portState);
    }

    /**
     * @notice Returns an array of all compliance notifications logged so far.
     * @return An array of ComplianceNotification structs.
     */
    function getNotifications()
        external
        view
        returns (ComplianceNotification[] memory)
    {
        return notifications;
    }
}
