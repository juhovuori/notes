""" Custom errors """

class Error(BaseException):
    """Bass class for alĺ errors from app"""
    status = 500

class InvalidRequest(Error):
    """The request was invalid"""
    status = 400
    def __init__(self, message = "Invalid request"):
        super(InvalidRequest, self).__init__(message)

class NotFound(InvalidRequest):
    """The requested note was not found"""
    status = 404
    def __init__(self, id, message = "Not found"):
        super(NotFound, self).__init__(message)
        self.id = id
