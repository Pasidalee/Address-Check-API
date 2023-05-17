import ballerina/sql;
import ballerinax/postgresql;
import ballerina/http;

configurable string host = ?;
configurable string username = ?;
configurable string password = ?;
configurable string database = ?;
configurable int port = ?;

const APPROVED = "approved";
const DECLINED = "declined";
const NO_ROWS_ERROR_MSG = "Query did not retrieve any rows.";
const USER_NOT_FOUND = "User not found";

type Address record {|
    string? address_line1;
    string? address_line2;
    string? city;
|};

isolated service / on new http:Listener(9090) {
    private final postgresql:Client dbClient;

    public isolated function init() returns error? {
        // Initialize the database
        self.dbClient = check new (host, username, password, database, port);
    }

    isolated resource function get addresscheck(string userId, string address) returns error?        {
        string userAddress = check getUserAddress(userId, self.dbClient);
        if userAddress.equalsIgnoreCaseAscii(address.trim()) {
            _ = check updateValidation(userId, self.dbClient);
        }
    }
}

  isolated function getUserAddress(string userId, postgresql:Client dbClient) returns string|error {
        sql:ParameterizedQuery query = `SELECT address_line1, address_line2, city FROM user_details WHERE user_id = ${userId}`;
        Address address = check dbClient->queryRow(query);
        string completeAddress = "";
        string? addressLine1 = address?.address_line1;
        string? addressLine2 = address?.address_line2;
        string? city = address?.city;
        if addressLine1 != () {
            completeAddress = addressLine1;
        }
        if addressLine2 != () {
            completeAddress += ", " + addressLine2;
        }
        if city != () {
            completeAddress += ", " + city;
        }
        return completeAddress;
    }

isolated function updateValidation(string userId, postgresql:Client dbClient) returns error? {
    sql:ParameterizedQuery query = `UPDATE certificate_requests SET address_check = true WHERE user_id = ${userId} AND 
            status != ${APPROVED} AND status != ${DECLINED}`;
    _ = check dbClient->execute(query);
}
