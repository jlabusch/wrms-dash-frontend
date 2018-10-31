from django.conf import settings
from django.contrib.auth.hashers import check_password
from django.contrib.auth.models import Group, User

from .wrms import WrmsClient
from .wrms import LoginException

#TODO: add logout buttons to client pages

class WrmsBackend:
    """
    Authenticate against WRMS login

    """
    def authenticate(self, username=None, password=None):
        '''Log into the dashboard using WRMS login details. Login will fail immediately if WRMS login details are incorrect.
           Checks if user is already in Dashboard database. If not, creates user using WRMS details.
           Adds user to correct group based on WRMS org id. This will give access to the dashboard page for that org.
           If user is in the 'superuser' list for Catalyst staff, superuser will be created with access to all clients.
        '''
        try:
            wrms = WrmsClient(username=username, password=password)
        except:
            return None
        try:
            # Search database for existing user
            user = User.objects.get(username=username)
            return user
        except User.DoesNotExist:
            # Create a new user.
            user = User(username=username)
            #add user details from WRMS.
            ######################################
            #TODO: Delete this code for V1.1, if we delete users from django database on logout.
            if wrms.email != None:
                user.email = wrms.email
            if wrms.fullname != "":
                name = wrms.fullname.rsplit(" ", 1)
                #Add their name if there is more than 1 word in the wrms 'fullname' field. 'Fullname' is split into first and last, on last space
                if len(name) > 1:
                    user.last_name = name[-1]
                    user.first_name = name[0]
            ######################################

            #if wrms org id for user is in the list below for superusers, create superuser
            if wrms.org_id in superusers:
                user.is_staff = True
                user.is_superuser = True
                user.save()
                return user
            else: #if org id is not catalyst, add them to the group for their org
                user.save()
                group_name = str(wrms.org_id)
                try:
                    group = Group.objects.get(name=group_name)
                except Exception: #if there's no group for that org, create a group
                    group = Group()
                    group.name=str(wrms.org_id)
                    group.save()
                user.groups.add(group)
                return user


    def get_user(self, user_id):
        '''Required for backend to work properly - unchanged in most scenarios'''
        try:
            return User.objects.get(pk=user_id)
        except User.DoesNotExist:
            return None

#wrms org ids for users who should have superuser permissions and access to all clients (ie, catalyst staff)
superusers = [
    1137,
]
