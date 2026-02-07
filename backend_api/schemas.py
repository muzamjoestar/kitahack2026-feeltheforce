from pydantic import BaseModel
from typing import Optional

class MatricCardDetails(BaseModel):
    matric_number: int
    name: str
    kulliyyah: str
    
class MatricCardResponse(BaseModel):
    valid: bool
    details: Optional[MatricCardDetails] = None
    message: str