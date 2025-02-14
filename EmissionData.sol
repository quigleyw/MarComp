// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./VesselRegistration.sol";
import "./Notification.sol";

/**
 * @title EmissionData
 * @dev Records sulfur emission data for vessels, checks compliance thresholds,
 *      and notifies relevant parties of non-compliant readings.
 */
contract EmissionData {
    /// @dev Represents a single emission record with relevant data fields.
    struct Emission {
        uint256 timestamp;
        string vesselId;
        uint256 sulfurContent;  // e.g., scaled by 1000 if desired
        string position;        // can be lat-lon or named region
        bool isECA;            // whether the area is an Emission Control Area
        bool isCompliant;      // compliance result with sulfur regulations
    }

    /**
     * @dev Instead of storing only the latest emission, we store an array of emissions for each vessel ID.
     *      This allows historical auditing.
     */
    mapping(string => Emission[]) private vesselEmissions;

    /// @notice Fixed sulfur thresholds expressed in some consistent unit (e.g., parts per million scaled).
    uint256 private constant ECA_SULFUR_LIMIT = 100;   // e.g., 0.10%
    uint256 private constant NON_ECA_SULFUR_LIMIT = 500; // e.g., 0.50%

    VesselRegistration public vesselRegistration;
    Notification public notification;

    /// @notice Contract administrator with special privileges, if needed.
    address public admin;

    /// @dev Restricts to the admin of this contract.
    modifier onlyAdmin() {
        require(msg.sender == admin, "Not authorized");
        _;
    }

    /**
     * @dev Checks if the specified vessel is registered in VesselRegistration.
     */
    modifier onlyRegisteredVessel(string memory vesselId) {
        require(
            vesselRegistration.isVesselRegistered(vesselId),
            "Vessel not registered"
        );
        _;
    }

    /**
     * @param vesselRegistrationAddress Address of the deployed VesselRegistration contract.
     * @param notificationAddress Address of the deployed Notification contract.
     */
    constructor(address vesselRegistrationAddress, address notificationAddress) {
        vesselRegistration = VesselRegistration(vesselRegistrationAddress);
        notification = Notification(notificationAddress);
        admin = msg.sender;
    }

    /**
     * @dev Emitted when a new emission record is successfully stored.
     * @param vesselId The vessel's unique identifier (e.g., IMO number).
     * @param sulfurContent The measured sulfur content in scaled units.
     * @param position The position or region where the measurement was taken.
     * @param isECA Indicates if the location is an Emission Control Area.
     * @param isCompliant True if within allowed thresholds, false otherwise.
     */
    event EmissionRecorded(
        string vesselId,
        uint256 sulfurContent,
        string position,
        bool isECA,
        bool isCompliant
    );

    /**
     * @notice Records a new sulfur emission reading for the given vessel.
     * @dev Enforces compliance checks based on whether the location is ECA or not,
     *      and notifies regulators if non-compliance is detected.
     * @param vesselId The vessel's identifier (must be registered).
     * @param sulfurContent The measured sulfur content (scaled, e.g. 100 for 0.10%).
     * @param position A location string or lat-lon reference.
     * @param isECA True if the position is within an Emission Control Area.
     */
    function recordEmission(
        string memory vesselId,
        uint256 sulfurContent,
        string memory position,
        bool isECA
    ) public onlyRegisteredVessel(vesselId) {
        // Determine compliance thresholds
        bool isCompliant;
        if (isECA) {
            isCompliant = (sulfurContent <= ECA_SULFUR_LIMIT);
        } else {
            isCompliant = (sulfurContent <= NON_ECA_SULFUR_LIMIT);
        }

        // Construct and store the emission record
        Emission memory newEmission = Emission({
            timestamp: block.timestamp,
            vesselId: vesselId,
            sulfurContent: sulfurContent,
            position: position,
            isECA: isECA,
            isCompliant: isCompliant
        });
        vesselEmissions[vesselId].push(newEmission);

        // Emit event for off-chain or other on-chain listeners
        emit EmissionRecorded(
            vesselId,
            sulfurContent,
            position,
            isECA,
            isCompliant
        );

        // Trigger non-compliance logic if needed
        if (!isCompliant) {
            string memory flagState = vesselRegistration.getFlagState(vesselId);
            string memory portState = notification.getPortState(position);

            // Build a domain-specific message
            string memory message = isECA
                ? "Non-compliance: Exceeds 0.10% sulfur limit in ECA."
                : "Non-compliance: Exceeds 0.50% sulfur limit outside ECA.";

            // Report the non-compliance event
            notification.reportNonCompliance(
                vesselId,
                message,
                flagState,
                portState
            );
        }
    }

    /**
     * @notice Retrieves the full emission history for a vessel.
     * @param vesselId The vessel's identifier.
     * @return An array of Emission structs.
     */
    function getEmissionHistory(string calldata vesselId)
        external
        view
        returns (Emission[] memory)
    {
        return vesselEmissions[vesselId];
    }
}
