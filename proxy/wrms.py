import urllib3
import requests
from pprint import pprint

TEST_URL = "https://wrms2-staging.wgtn.cat-it.co.nz"
PROD_URL = "https://wrms.catalyst.net.nz"

class WrmsClient:
    def __init__(self, production=False, debug=False, username=None, password=None):
        """ The WrmsClient class is the interface to wrms.

        It takes care of authentication etc.

        Args:
            production - boolean(True): Whether to connect to the production server
            debug - boolean(False): Whether to output debug messages
            username - str(None): Username to login with
            password - str(None): Password to login with

        """
        if production:
            self.base_url = PROD_URL
        else:
            self.base_url = TEST_URL
        self.authenticate(username, password)


    def validate_token(self):
        """ Validate if a token is valid

        """
        try:
            res = self.report("user", ["user_id"], extra_params={"user": "MY_USER_ID"})
            self.user_id = res[0]["user_id"]
            return True
        except:
            return False

    def authenticate(self, username=None, password=None):
        """ Perform the authentication ritual.
        Check username and password
        Args:
            username - str(None): The user to login as.
            password - str(None): The password of this user

        """
        # If a username and password are supplied, assume the user supplies good ones.
        if username is not None and password is not None:
            self.login(username, password)
            print ('logging in')
            return
        else:
            raise Exception('Enter a username and password')

    def login(self, username, password, production=False):
        """ Log in to WRMS
        """
        url = self.base_url + '/api2/login'

        payload = {
            'username': username,
            'user_id': '',
            'password': password,
        }

        try:
            response = requests.post(url, data=payload)
        except ConnectionError:
            print ('\n!!!!!!!!!!!!!!!!!WRMS CONNECTION FAILED... TRYING AGAIN\n') #TODO: check that this fix actually works
            response = requests.post(url, data=payload)

        content = response.json()
        if not content['success']:
            raise LoginException

        self.user_id = content['response']['user_id']
        self.org_id = content['response']['organisation_id']
        self.fullname = content['response']['fullname']
        self.email = content['response']['email']

        print (self.email, type(self.email))

    def report(self, report_type, display_fields, page_size=1000, page_no=1, extra_params=None):
        """ Run a report_type report against the wrms api

        Args:
            report_type - str: The type of report
            display_fields - iterable: List of the fields to return
            page_size - int [1000]: The Number of results to return
            page_no - int [1]: The page of results to return
            extra_params - dict [None]: A dictionary of extra parameters to pass in
        Returns:
            A list of all the results

        """
        if extra_params is None:
            extra_params = {}
            url = self.base_url + "/api2/report"

        params = extra_params
        params.update({
            "report_type": report_type,
            "display_fields": ",".join(display_fields),
            "page_size": page_size,
            "page_no": page_no,
        })

        if self.debug:
            params["output_format"] = "pretty_json"

        results = self.get_request(url, params)
        # Check for errors
        if not results["success"]:
            raise WrmsException(results["message"])
        return results["response"]["results"]

class WrmsException(Exception):
    pass

class LoginException(WrmsException):
    pass
